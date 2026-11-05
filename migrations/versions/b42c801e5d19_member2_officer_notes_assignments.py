"""Member 2 officer notes visibility + department-only assignments.

Revision ID: b42c801e5d19
Revises: f5d83b1a0c62

Existing comments default to public for backward compatibility. All new
internal notes are explicitly stored with visibility='internal'.
"""
from alembic import op
import sqlalchemy as sa

revision = 'b42c801e5d19'
down_revision = 'f5d83b1a0c62'
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table('issue_comments') as batch:
        batch.add_column(sa.Column('visibility', sa.String(16), nullable=False, server_default='public'))
    with op.batch_alter_table('issue_assignments') as batch:
        batch.alter_column('assigned_to', existing_type=sa.Integer(), nullable=True)


def downgrade():
    # Department-only assignments have NULL assigned_to; deleting them to
    # downgrade would lose audit data. Refuse instead of deleting records.
    connection = op.get_bind()
    count = connection.execute(sa.text('SELECT COUNT(*) FROM issue_assignments WHERE assigned_to IS NULL')).scalar_one()
    if count:
        raise RuntimeError('Cannot downgrade: department-only assignments require manual archival before downgrade')
    with op.batch_alter_table('issue_assignments') as batch:
        batch.alter_column('assigned_to', existing_type=sa.Integer(), nullable=False)
    with op.batch_alter_table('issue_comments') as batch:
        batch.drop_column('visibility')
