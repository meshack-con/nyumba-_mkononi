from datetime import datetime
from enum import Enum
from sqlalchemy import Boolean, DateTime, Enum as SqlEnum, ForeignKey, Integer, JSON, String, Text, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from .database import Base
class UserRole(str, Enum):
    BUYER = "buyer"
    SELLER = "seller"
class PropertyType(str, Enum):
    APARTMENT = "apartment"
    NYUMBA = "nyumba"
    STUDIO = "studio"
    VILLA = "villa"
class PropertyMode(str, Enum):
    RENT = "rent"
    SALE = "sale"
class PropertyStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    EXPIRED = "expired"
class NotificationType(str, Enum):
    PLATFORM = "platform"
    OWNER = "owner"
class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(primary_key=True)
    jina_kamili: Mapped[str] = mapped_column(String(150))
    namba_ya_simu: Mapped[str] = mapped_column(String(30))
    username: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    role: Mapped[UserRole] = mapped_column(SqlEnum(UserRole, name="user_role"))
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False)
    eneo: Mapped[str | None] = mapped_column(String(150), nullable=True)
    profile_picha_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    properties: Mapped[list["Property"]] = relationship(back_populates="owner")
    favorites: Mapped[list["Favorite"]] = relationship(back_populates="user", cascade="all, delete-orphan")
class Property(Base):
    __tablename__ = "properties"
    id: Mapped[int] = mapped_column(primary_key=True)
    owner_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    jina: Mapped[str] = mapped_column(String(180))
    aina: Mapped[PropertyType] = mapped_column(SqlEnum(PropertyType, name="property_type"))
    mode: Mapped[PropertyMode] = mapped_column(SqlEnum(PropertyMode, name="property_mode"))
    price: Mapped[int] = mapped_column(Integer)
    location_label: Mapped[str] = mapped_column(String(180))
    latitude: Mapped[float]
    longitude: Mapped[float]
    has_wifi: Mapped[bool] = mapped_column(Boolean, default=False)
    car_parking: Mapped[bool] = mapped_column(Boolean, default=False)
    indoor_toilet: Mapped[bool] = mapped_column(Boolean, default=False)
    has_electricity: Mapped[bool] = mapped_column(Boolean, default=False)
    water_inside: Mapped[bool] = mapped_column(Boolean, default=False)
    water_nearby: Mapped[bool] = mapped_column(Boolean, default=False)
    furnished: Mapped[bool] = mapped_column(Boolean, default=False)
    swimming_pool: Mapped[bool] = mapped_column(Boolean, default=False)
    view_count: Mapped[int] = mapped_column(Integer, default=0)
    description: Mapped[str] = mapped_column(Text)
    photo_urls: Mapped[list[str]] = mapped_column(JSON)
    verification_doc_url: Mapped[str] = mapped_column(String(500))
    status: Mapped[PropertyStatus] = mapped_column(SqlEnum(PropertyStatus, name="property_status"), default=PropertyStatus.PENDING)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    owner: Mapped[User] = relationship(back_populates="properties")
    favorites: Mapped[list["Favorite"]] = relationship(back_populates="property", cascade="all, delete-orphan")
    messages: Mapped[list["Message"]] = relationship(cascade="all, delete-orphan")
class Favorite(Base):
    __tablename__ = "favorites"
    __table_args__ = (UniqueConstraint("user_id", "property_id", name="uq_favorite_user_property"),)
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    property_id: Mapped[int] = mapped_column(ForeignKey("properties.id", ondelete="CASCADE"), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    user: Mapped[User] = relationship(back_populates="favorites")
    property: Mapped[Property] = relationship(back_populates="favorites")
class LoginEvent(Base):
    __tablename__ = "login_events"
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    role: Mapped[UserRole] = mapped_column(SqlEnum(UserRole, name="user_role"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
class Message(Base):
    __tablename__ = "messages"
    id: Mapped[int] = mapped_column(primary_key=True)
    property_id: Mapped[int] = mapped_column(ForeignKey("properties.id", ondelete="CASCADE"), index=True)
    sender_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    receiver_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    content: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    property: Mapped["Property"] = relationship(back_populates="messages")
    sender: Mapped["User"] = relationship(foreign_keys=[sender_id])
    receiver: Mapped["User"] = relationship(foreign_keys=[receiver_id])
class Notification(Base):
    """Arifa kutoka kwa platform yenyewe (Nyumba Mkononi) kwenda kwa
    mtumiaji - mfano: tangazo limeruhusiwa/limekataliwa, karibu, n.k.
    Arifa za ujumbe kutoka kwa mmiliki wa nyumba zinatumia Message/
    conversations moja kwa moja - hazihitaji rekodi hapa."""
    __tablename__ = "notifications"
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    title: Mapped[str] = mapped_column(String(200))
    body: Mapped[str] = mapped_column(Text)
    property_id: Mapped[int | None] = mapped_column(ForeignKey("properties.id", ondelete="SET NULL"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
