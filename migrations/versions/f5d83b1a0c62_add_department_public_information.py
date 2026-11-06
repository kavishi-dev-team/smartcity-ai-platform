"""Add optional public department directory information.

Revision ID: f5d83b1a0c62
Revises: 838ec231d5e8

All new columns are nullable. Existing department rows are not modified.
"""
from alembic import op
import sqlalchemy as sa

revision = 'f5d83b1a0c62'
down_revision = '838ec231d5e8'
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table('departments') as batch:
        batch.add_column(sa.Column('responsibilities', sa.Text(), nullable=True))
        batch.add_column(sa.Column('contact_email', sa.String(255), nullable=True))
        batch.add_column(sa.Column('contact_phone', sa.String(40), nullable=True))
        batch.add_column(sa.Column('office_address', sa.String(255), nullable=True))
        batch.add_column(sa.Column('office_city', sa.String(100), nullable=True))
        batch.add_column(sa.Column('office_latitude', sa.Float(), nullable=True))
        batch.add_column(sa.Column('office_longitude', sa.Float(), nullable=True))
        batch.add_column(sa.Column('operating_hours', sa.String(200), nullable=True))


def downgrade():
    with op.batch_alter_table('departments') as batch:
        for name in ('operating_hours', 'office_longitude', 'office_latitude',
                     'office_city', 'office_address', 'contact_phone',
                     'contact_email', 'responsibilities'):
            batch.drop_column(name)
