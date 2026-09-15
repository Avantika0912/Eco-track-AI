"""
models.py
SQLAlchemy ORM models — the Python-side mirror of schema.sql.
Other members import these classes to read/write the DB without
writing raw SQL.
"""
 
from sqlalchemy import (
    Column, Integer, String, Numeric, Text, Date, DateTime,
    ForeignKey, ARRAY, func
)
from sqlalchemy.orm import relationship
from database import Base
 
 
class Category(Base):
    __tablename__ = "categories"
 
    category_id = Column(Integer, primary_key=True)
    category_name = Column(String(100), unique=True, nullable=False)
    description = Column(Text)
    created_at = Column(DateTime, server_default=func.now())
 
    products = relationship("Product", back_populates="category")
 
 
class Product(Base):
    __tablename__ = "products"
 
    product_id = Column(Integer, primary_key=True)
    product_name = Column(String(200), nullable=False)
    category_id = Column(Integer, ForeignKey("categories.category_id"))
    unit = Column(String(20), default="kg")
    aliases = Column(ARRAY(String))
    created_at = Column(DateTime, server_default=func.now())
 
    category = relationship("Category", back_populates="products")
    emission_factors = relationship("EmissionFactor", back_populates="product")
 
 
class EmissionFactor(Base):
    __tablename__ = "emission_factors"
 
    factor_id = Column(Integer, primary_key=True)
    product_id = Column(Integer, ForeignKey("products.product_id"))
    category_id = Column(Integer, ForeignKey("categories.category_id"))
    co2e_per_unit = Column(Numeric(10, 4), nullable=False)
    unit = Column(String(20), default="kg")
    source = Column(String(200))
    valid_from = Column(Date)
    valid_to = Column(Date)
    created_at = Column(DateTime, server_default=func.now())
 
    product = relationship("Product", back_populates="emission_factors")
 
 
class Bill(Base):
    __tablename__ = "bills"
 
    bill_id = Column(Integer, primary_key=True)
    user_id = Column(Integer)
    store_name = Column(String(200))
    bill_date = Column(Date)
    upload_date = Column(DateTime, server_default=func.now())
    image_path = Column(Text)
    raw_ocr_text = Column(Text)
    total_amount = Column(Numeric(10, 2))
    total_emission_kg = Column(Numeric(10, 4))
    status = Column(String(30), default="processing")
 
    items = relationship("BillItem", back_populates="bill", cascade="all, delete-orphan")
 
 
class BillItem(Base):
    __tablename__ = "bill_items"
 
    item_id = Column(Integer, primary_key=True)
    bill_id = Column(Integer, ForeignKey("bills.bill_id"))
    product_id = Column(Integer, ForeignKey("products.product_id"))
    raw_text = Column(String(300))
    matched_confidence = Column(Numeric(5, 4))
    quantity = Column(Numeric(10, 3), default=1)
    unit = Column(String(20), default="kg")
    price = Column(Numeric(10, 2))
    emission_kg = Column(Numeric(10, 4))
    created_at = Column(DateTime, server_default=func.now())
 
    bill = relationship("Bill", back_populates="items")
    product = relationship("Product")
 

