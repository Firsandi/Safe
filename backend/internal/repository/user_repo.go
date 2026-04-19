package repository

import (
    "safe-backend/internal/model"
    "github.com/jmoiron/sqlx"
)

type UserRepository struct {
    db *sqlx.DB
}

func NewUserRepository(db *sqlx.DB) *UserRepository {
    return &UserRepository{db: db}
}

func (r *UserRepository) FindByEmail(email string) (*model.User, error) {
    var user model.User
    err := r.db.Get(&user,
        "SELECT user_id, nama, email, password, nomor_hp, fcm_token, created_at FROM users WHERE email=$1",
        email,
    )
    if err != nil {
        return nil, err
    }
    return &user, nil
}

func (r *UserRepository) Create(u *model.User) error {
    row := r.db.QueryRowx(
        `INSERT INTO users (nama, email, password, nomor_hp)
         VALUES ($1, $2, $3, $4)
         RETURNING user_id, created_at`,
        u.Nama, u.Email, u.Password, u.NomorHP,
    )
    return row.Scan(&u.UserID, &u.CreatedAt)
}