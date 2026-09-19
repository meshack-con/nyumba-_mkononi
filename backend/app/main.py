from datetime import datetime, timedelta, timezone
from pathlib import Path
from uuid import uuid4

from fastapi import Depends, FastAPI, File, Form, HTTPException, Query, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import and_, func, or_, select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload

import cloudinary
import cloudinary.uploader

from .admin import router as admin_router
from .auth import create_access_token, get_current_user, hash_password, verify_password
from .database import Base, engine, get_db, settings
from .models import Favorite, LoginEvent, Message, Property, PropertyMode, PropertyStatus, PropertyType, User, UserRole
from .schemas import (
    AuthResponse,
    FavoriteResponse,
    LoginRequest,
    MessageCreate,
    MessageResponse,
    PropertyResponse,
    PropertyWithOwnerResponse,
    PublicPropertyResponse,
    UserCreate,
    UserResponse,
)

BASE_DIR = Path(__file__).resolve().parent.parent
UPLOADS_DIR = BASE_DIR / "uploads"
UPLOADS_DIR.mkdir(exist_ok=True)

app = FastAPI(title="Nyumba Mkononi API", version="1.0.0")
app.mount("/uploads", StaticFiles(directory=UPLOADS_DIR), name="uploads")
app.include_router(admin_router)

cloudinary.config(
    cloud_name=settings.cloudinary_cloud_name,
    api_key=settings.cloudinary_api_key,
    api_secret=settings.cloudinary_api_secret,
    secure=True,
)

origins = [origin.strip() for origin in settings.cors_origins.split(",") if origin.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def create_tables() -> None:
    Base.metadata.create_all(bind=engine)


def ensure_seller(user: User) -> None:
    if user.role != UserRole.SELLER:
        raise HTTPException(status_code=403, detail="Hatua hii ni ya seller pekee")


def public_property_filter():
    now = datetime.now(timezone.utc)
    return and_(
        Property.status == PropertyStatus.APPROVED,
        (Property.expires_at.is_(None) | (Property.expires_at > now)),
    )


def posted_within_cutoff(value: str) -> datetime | None:
    now = datetime.now(timezone.utc)
    if value == "today":
        return now.replace(hour=0, minute=0, second=0, microsecond=0)
    if value == "week":
        return now - timedelta(days=7)
    if value == "month":
        return now - timedelta(days=30)
    if value == "year":
        return now - timedelta(days=365)
    return None


async def save_upload(upload: UploadFile, folder: str) -> str:
    extension = Path(upload.filename or "").suffix.lower()
    allowed_extensions = {".jpg", ".jpeg", ".png", ".webp", ".pdf"}
    if extension not in allowed_extensions:
        raise HTTPException(status_code=400, detail="Aina ya file hairuhusiwi")
    contents = await upload.read()
    resource_type = "raw" if extension == ".pdf" else "image"
    result = cloudinary.uploader.upload(
        contents,
        folder=f"nyumba_mkononi/{folder}",
        resource_type=resource_type,
        public_id=uuid4().hex,
    )
    return result["secure_url"]


@app.post("/auth/register", response_model=AuthResponse, status_code=201)
def register(payload: UserCreate, db: Session = Depends(get_db)):
    if db.scalar(select(User).where(User.username == payload.username)):
        raise HTTPException(status_code=409, detail="Username tayari ipo")
    user = User(
        jina_kamili=payload.jina_kamili,
        namba_ya_simu=payload.namba_ya_simu,
        username=payload.username,
        password_hash=hash_password(payload.password),
        role=payload.role,
        email=str(payload.email) if payload.email else None,
        eneo=payload.eneo,
    )
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Username tayari ipo") from None
    db.refresh(user)
    return AuthResponse(access_token=create_access_token(user), user=user)


@app.post("/auth/login", response_model=AuthResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(User.username == payload.username))
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Username au password si sahihi")
    db.add(LoginEvent(user_id=user.id, role=user.role))
    db.commit()
    return AuthResponse(access_token=create_access_token(user), user=user)


# --- Public-facing property endpoints ---------------------------------
# Hizi zinatumia PublicPropertyResponse (HAINA verification_doc_url)
# kwa sababu zinaweza kufikiwa na buyer yeyote, hata bila kuwa
# ameautheticate. Hati ya uthibitisho ni taarifa nyeti - haipaswi
# kuvuja kwa umma.

@app.get("/properties", response_model=list[PublicPropertyResponse])
def list_properties(
    location: str | None = None,
    min_price: int | None = Query(default=None, ge=0),
    max_price: int | None = Query(default=None, ge=0),
    property_type: PropertyType | None = None,
    mode: PropertyMode | None = None,
    has_wifi: bool | None = None,
    car_parking: bool | None = None,
    indoor_toilet: bool | None = None,
    has_electricity: bool | None = None,
    water_inside: bool | None = None,
    water_nearby: bool | None = None,
    furnished: bool | None = None,
    swimming_pool: bool | None = None,
    posted_within: str | None = Query(default=None, pattern="^(today|week|month|year)$"),
    db: Session = Depends(get_db),
):
    # Idadi ya favorites kwa kila property - inatumika kupanga matokeo
    # ya default (bila filter) kuanzia yaliyopendwa zaidi.
    fav_count_subq = (
        select(Favorite.property_id, func.count(Favorite.id).label("fav_count"))
        .group_by(Favorite.property_id)
        .subquery()
    )

    query = (
        select(Property)
        .outerjoin(fav_count_subq, fav_count_subq.c.property_id == Property.id)
        .where(public_property_filter())
    )
    if location:
        query = query.where(Property.location_label.ilike(f"%{location}%"))
    if min_price is not None:
        query = query.where(Property.price >= min_price)
    if max_price is not None:
        query = query.where(Property.price <= max_price)
    if property_type is not None:
        query = query.where(Property.aina == property_type)
    if mode is not None:
        query = query.where(Property.mode == mode)
    if has_wifi is not None:
        query = query.where(Property.has_wifi == has_wifi)
    if car_parking is not None:
        query = query.where(Property.car_parking == car_parking)
    if indoor_toilet is not None:
        query = query.where(Property.indoor_toilet == indoor_toilet)
    if has_electricity is not None:
        query = query.where(Property.has_electricity == has_electricity)
    if water_inside is not None:
        query = query.where(Property.water_inside == water_inside)
    if water_nearby is not None:
        query = query.where(Property.water_nearby == water_nearby)
    if furnished is not None:
        query = query.where(Property.furnished == furnished)
    if swimming_pool is not None:
        query = query.where(Property.swimming_pool == swimming_pool)
    if posted_within is not None:
        cutoff = posted_within_cutoff(posted_within)
        if cutoff is not None:
            query = query.where(Property.created_at >= cutoff)

    # Algorithm ya kupanga: zilizopendwa zaidi (favorites), kisha
    # zilizoangaliwa zaidi (view_count), kisha mpya zaidi. Hii inatumika
    # kama default (mtumiaji hajaweka filter) na pia kama tiebreaker
    # anapotumia filters.
    query = query.order_by(
        func.coalesce(fav_count_subq.c.fav_count, 0).desc(),
        Property.view_count.desc(),
        Property.created_at.desc(),
    )
    return list(db.scalars(query).unique().all())


@app.get("/properties/{property_id}", response_model=PublicPropertyResponse)
def get_property(property_id: int, db: Session = Depends(get_db)):
    property_item = db.scalar(select(Property).where(Property.id == property_id, public_property_filter()))
    if property_item is None:
        raise HTTPException(status_code=404, detail="Tangazo halipatikani")
    property_item.view_count += 1
    db.commit()
    db.refresh(property_item)
    return property_item


# --- Owner contact info (kwa sehemu ya "eneo la nyumba" / mawasiliano) --

@app.get("/properties/{property_id}/contact", response_model=PropertyWithOwnerResponse)
def get_property_contact(property_id: int, db: Session = Depends(get_db)):
    property_item = db.scalar(
        select(Property).options(joinedload(Property.owner)).where(Property.id == property_id, public_property_filter())
    )
    if property_item is None:
        raise HTTPException(status_code=404, detail="Tangazo halipatikani")
    base = PublicPropertyResponse.model_validate(property_item).model_dump()
    return PropertyWithOwnerResponse(
        **base,
        owner_jina=property_item.owner.jina_kamili,
        owner_simu=property_item.owner.namba_ya_simu,
        owner_email=property_item.owner.email,
    )


# --- Messages (chat kati ya buyer na seller kuhusu tangazo maalum) -----

@app.post("/properties/{property_id}/messages", response_model=MessageResponse, status_code=201)
def send_message(
    property_id: int,
    payload: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    property_item = db.get(Property, property_id)
    if property_item is None:
        raise HTTPException(status_code=404, detail="Tangazo halipatikani")
    if current_user.id == property_item.owner_id:
        if payload.receiver_id is None:
            raise HTTPException(status_code=400, detail="receiver_id inahitajika kwa mmiliki")
        receiver_id = payload.receiver_id
    else:
        receiver_id = property_item.owner_id
    message = Message(
        property_id=property_id,
        sender_id=current_user.id,
        receiver_id=receiver_id,
        content=payload.content,
    )
    db.add(message)
    db.commit()
    db.refresh(message)
    return message


@app.get("/properties/{property_id}/messages", response_model=list[MessageResponse])
def get_messages(
    property_id: int,
    with_user_id: int | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    property_item = db.get(Property, property_id)
    if property_item is None:
        raise HTTPException(status_code=404, detail="Tangazo halipatikani")
    other_id = with_user_id
    if other_id is None:
        if current_user.id != property_item.owner_id:
            other_id = property_item.owner_id
        else:
            raise HTTPException(status_code=400, detail="with_user_id inahitajika")
    query = (
        select(Message)
        .where(
            Message.property_id == property_id,
            or_(
                and_(Message.sender_id == current_user.id, Message.receiver_id == other_id),
                and_(Message.sender_id == other_id, Message.receiver_id == current_user.id),
            ),
        )
        .order_by(Message.created_at.asc())
    )
    messages = list(db.scalars(query).all())
    unread_ids = [m.id for m in messages if m.receiver_id == current_user.id and m.read_at is None]
    if unread_ids:
        db.execute(update(Message).where(Message.id.in_(unread_ids)).values(read_at=func.now()))
        db.commit()
        now = datetime.now(timezone.utc)
        for m in messages:
            if m.id in unread_ids:
                m.read_at = now
    return messages


# --- Seller-only property endpoints ------------------------------------
# Hizi zinatumia PropertyResponse kamili (INA verification_doc_url)
# kwa sababu ni seller mwenyewe, aliyeauthenticate, akiona taarifa zake.

@app.post("/properties", response_model=PropertyResponse, status_code=201)
async def create_property(
    jina: str = Form(...),
    aina: PropertyType = Form(...),
    mode: PropertyMode = Form(...),
    price: int = Form(..., ge=0),
    location_label: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    has_wifi: bool = Form(False),
    car_parking: bool = Form(False),
    indoor_toilet: bool = Form(False),
    has_electricity: bool = Form(False),
    water_inside: bool = Form(False),
    water_nearby: bool = Form(False),
    furnished: bool = Form(False),
    swimming_pool: bool = Form(False),
    description: str = Form(...),
    photos: list[UploadFile] = File(...),
    verification_doc: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    ensure_seller(current_user)
    if len(photos) != 3:
        raise HTTPException(status_code=400, detail="Tuma picha 3 za nyumba")
    photo_urls = [await save_upload(photo, "properties") for photo in photos]
    verification_doc_url = await save_upload(verification_doc, "verification-docs")
    property_item = Property(
        owner_id=current_user.id,
        jina=jina,
        aina=aina,
        mode=mode,
        price=price,
        location_label=location_label,
        latitude=latitude,
        longitude=longitude,
        has_wifi=has_wifi,
        car_parking=car_parking,
        indoor_toilet=indoor_toilet,
        has_electricity=has_electricity,
        water_inside=water_inside,
        water_nearby=water_nearby,
        furnished=furnished,
        swimming_pool=swimming_pool,
        description=description,
        photo_urls=photo_urls,
        verification_doc_url=verification_doc_url,
        status=PropertyStatus.PENDING,
    )
    db.add(property_item)
    db.commit()
    db.refresh(property_item)
    return property_item


@app.get("/properties/mine", response_model=list[PropertyResponse])
def list_my_properties(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    ensure_seller(current_user)
    query = select(Property).where(Property.owner_id == current_user.id).order_by(Property.created_at.desc())
    return list(db.scalars(query).all())


# --- Favorites -----------------------------------------------------------

@app.get("/favorites", response_model=list[FavoriteResponse])
def list_favorites(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    query = (
        select(Favorite)
        .options(joinedload(Favorite.property))
        .where(Favorite.user_id == current_user.id)
        .order_by(Favorite.created_at.desc())
    )
    return list(db.scalars(query).unique().all())


@app.post("/favorites/{property_id}", response_model=FavoriteResponse, status_code=201)
def add_favorite(property_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    property_item = db.scalar(select(Property).where(Property.id == property_id, public_property_filter()))
    if property_item is None:
        raise HTTPException(status_code=404, detail="Tangazo halipatikani")
    existing = db.scalar(select(Favorite).where(Favorite.user_id == current_user.id, Favorite.property_id == property_id))
    if existing:
        raise HTTPException(status_code=409, detail="Tangazo tayari liko kwenye favorites")
    favorite = Favorite(user_id=current_user.id, property_id=property_id)
    db.add(favorite)
    db.commit()
    db.refresh(favorite)
    favorite.property = property_item
    return favorite


@app.delete("/favorites/{property_id}", status_code=204)
def remove_favorite(property_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    favorite = db.scalar(select(Favorite).where(Favorite.user_id == current_user.id, Favorite.property_id == property_id))
    if favorite is None:
        raise HTTPException(status_code=404, detail="Favorite haikupatikana")
    db.delete(favorite)
    db.commit()


@app.get("/health")
def health_check():
    return {"status": "ok"}
