"""
crud.py
Common read/write functions built on top of models.py.
These are the functions other members will actually call day-to-day
instead of writing raw SQLAlchemy queries themselves.
"""
 
from sqlalchemy.orm import Session
from sqlalchemy import func
from models import Category, Product, EmissionFactor, Bill, BillItem
 
 
# ---------- Categories & Products (used by Member 2) ----------
 
def get_all_categories(db: Session):
    return db.query(Category).all()
 
 
def get_all_products(db: Session):
    return db.query(Product).all()
 
 
def find_product_by_name(db: Session, name: str):
    """
    Simple exact/alias match. Member 2 can layer fuzzy/semantic
    matching on top of this, falling back to this function first.
    """
    product = db.query(Product).filter(
        func.lower(Product.product_name) == name.lower()
    ).first()
    if product:
        return product
 
    # check aliases array
    product = db.query(Product).filter(
        Product.aliases.any(name.lower())
    ).first()
    return product
 
 
def create_product(db: Session, name: str, category_id: int = None, unit: str = "kg"):
    product = Product(product_name=name, category_id=category_id, unit=unit)
    db.add(product)
    db.commit()
    db.refresh(product)
    return product
 
 
# ---------- Emission Factors (used by Member 4) ----------
 
def get_emission_factor_for_product(db: Session, product_id: int):
    """Latest active emission factor for a specific product."""
    return (
        db.query(EmissionFactor)
        .filter(EmissionFactor.product_id == product_id, EmissionFactor.valid_to.is_(None))
        .order_by(EmissionFactor.valid_from.desc())
        .first()
    )
 
 
def get_emission_factor_for_category(db: Session, category_id: int):
    """Fallback factor when no product-specific one exists."""
    return (
        db.query(EmissionFactor)
        .filter(EmissionFactor.category_id == category_id, EmissionFactor.valid_to.is_(None))
        .order_by(EmissionFactor.valid_from.desc())
        .first()
    )
 
 
# ---------- Bills & Bill Items (used by Members 1, 4, 5) ----------
 
def create_bill(db: Session, store_name: str, bill_date, image_path: str = None,
                 raw_ocr_text: str = None, total_amount=None):
    bill = Bill(
        store_name=store_name,
        bill_date=bill_date,
        image_path=image_path,
        raw_ocr_text=raw_ocr_text,
        total_amount=total_amount,
        status="processing",
    )
    db.add(bill)
    db.commit()
    db.refresh(bill)
    return bill
 
 
def add_bill_item(db: Session, bill_id: int, raw_text: str, quantity, unit: str,
                   price=None, product_id: int = None, matched_confidence=None):
    item = BillItem(
        bill_id=bill_id,
        product_id=product_id,
        raw_text=raw_text,
        matched_confidence=matched_confidence,
        quantity=quantity,
        unit=unit,
        price=price,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item
 
 
def update_item_emission(db: Session, item_id: int, emission_kg):
    item = db.query(BillItem).filter(BillItem.item_id == item_id).first()
    if item:
        item.emission_kg = emission_kg
        db.commit()
        db.refresh(item)
    return item
 
 
def get_bill_with_items(db: Session, bill_id: int):
    return db.query(Bill).filter(Bill.bill_id == bill_id).first()
 
 
def update_bill_total_emission(db: Session, bill_id: int):
    """Sum all item emissions and store on the bill (call after Member 4's calc)."""
    total = (
        db.query(func.sum(BillItem.emission_kg))
        .filter(BillItem.bill_id == bill_id)
        .scalar()
    ) or 0
    bill = db.query(Bill).filter(Bill.bill_id == bill_id).first()
    if bill:
        bill.total_emission_kg = total
        bill.status = "processed"
        db.commit()
        db.refresh(bill)
    return bill
 

