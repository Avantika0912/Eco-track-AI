"""
database.py
Connection setup for the Carbon Footprint project database — Supabase (PostgreSQL).
This is what Members 1, 2, 4, and 5 will import to talk to the DB.
"""
 
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
 
# ------------------------------------------------------------------
# SUPABASE CONNECTION STRING
# Get this from: Supabase dashboard -> Connect button -> Session pooler.
# It looks like:
#   postgresql://postgres.xxxxxxxxxxxx:[YOUR-PASSWORD]@aws-0-<region>.pooler.supabase.com:5432/postgres
# Replace [YOUR-PASSWORD] with your actual database password.
#
# Best practice: don't hardcode it here. Set it as an environment variable
# instead so you never accidentally commit your password to GitHub:
#   Mac/Linux:   export DATABASE_URL="postgresql://postgres.xxxx:yourpassword@aws-0-...supabase.com:5432/postgres"
#   Windows PS:  $env:DATABASE_URL="postgresql://postgres.xxxx:yourpassword@aws-0-...supabase.com:5432/postgres"
#
# If you just want it working quickly, you can paste your string directly
# into the fallback string below instead of using an environment variable.
# ------------------------------------------------------------------
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres.rljntlxgzrxgimrxzqso:t0kWWqJSspRaLufx@aws-0-ap-southeast-2.pooler.supabase.com:5432/postgres"
)
 
# Supabase requires SSL - sslmode="require" ensures the connection is encrypted.
engine = create_engine(
    DATABASE_URL,
    echo=False,
    pool_pre_ping=True,
    connect_args={"sslmode": "require"},
)
 
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
 
 
def get_db():
    """
    Dependency-style generator for use with FastAPI:
        @app.get("/products")
        def list_products(db: Session = Depends(get_db)):
            ...
    Or use directly:
        db = next(get_db())
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
 