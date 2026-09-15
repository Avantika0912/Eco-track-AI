"""
test_connection.py
Run this after setting up the database and running schema.sql + seed_data.sql
to confirm everything is wired correctly.
 
Usage:
    python test_connection.py
"""
 
from database import SessionLocal
import crud
 
db = SessionLocal()
 
print("=== Categories ===")
for c in crud.get_all_categories(db):
    print(f"  {c.category_id}: {c.category_name}")
 
print("\n=== Products ===")
for p in crud.get_all_products(db):
    print(f"  {p.product_id}: {p.product_name} ({p.unit})")
 
print("\n=== Test product lookup: 'atta' (alias for Wheat Flour) ===")
product = crud.find_product_by_name(db, "atta")
print(f"  Found: {product.product_name if product else 'NOT FOUND'}")
 
print("\n=== Test emission factor for 'Rice' ===")
rice = crud.find_product_by_name(db, "rice")
if rice:
    factor = crud.get_emission_factor_for_product(db, rice.product_id)
    print(f"  {rice.product_name}: {factor.co2e_per_unit} kg CO2e per {factor.unit}")
 
print("\n=== Sample bill ===")
bill = db.query(crud.Bill).first() if hasattr(crud, "Bill") else None
from models import Bill
bill = db.query(Bill).first()
if bill:
    print(f"  Bill #{bill.bill_id} from {bill.store_name}, items:")
    for item in bill.items:
        print(f"    - {item.raw_text}: qty={item.quantity} {item.unit}, price={item.price}")
 
db.close()
print("\nAll checks completed.")
 