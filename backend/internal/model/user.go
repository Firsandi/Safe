package model

import "time"

type User struct {
    UserID    string     `db:"user_id"    json:"user_id"`
    Nama      string     `db:"nama"       json:"nama"`
    Email     string     `db:"email"      json:"email"`
    Password  string     `db:"password"   json:"-"`
    NomorHP   string     `db:"nomor_hp"   json:"nomor_hp"`
    FcmToken  *string    `db:"fcm_token"  json:"fcm_token,omitempty"`
    CreatedAt time.Time  `db:"created_at" json:"created_at"`
}

type RegisterRequest struct {
    Nama     string `json:"nama"     binding:"required"`
    Email    string `json:"email"    binding:"required,email"`
    Password string `json:"password" binding:"required,min=6"`
    NomorHP  string `json:"nomor_hp" binding:"required"`
}

type LoginRequest struct {
    Email    string `json:"email"    binding:"required,email"`
    Password string `json:"password" binding:"required"`
}

type AuthResponse struct {
    Token string `json:"token"`
    User  User   `json:"user"`
}