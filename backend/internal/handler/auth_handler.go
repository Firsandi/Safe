package handler

import (
    "fmt"
    "net/http"
    "os"
    "time"

    "safe-backend/internal/model"
    "safe-backend/internal/repository"

    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
    "golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
    repo *repository.UserRepository
}

func NewAuthHandler(repo *repository.UserRepository) *AuthHandler {
    return &AuthHandler{repo: repo}
}

func (h *AuthHandler) Register(c *gin.Context) {
    var req model.RegisterRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    // Hash password
    hashed, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal proses password"})
        return
    }

    user := &model.User{
        Nama:     req.Nama,
        Email:    req.Email,
        Password: string(hashed),
        NomorHP:  req.NomorHP,
    }

    if err := h.repo.Create(user); err != nil {
        fmt.Printf("Error creating user: %v\n", err)
        c.JSON(http.StatusConflict, gin.H{"error": "Email sudah terdaftar atau kendala database"})
        return
    }

    token, err := generateToken(user.UserID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal buat token"})
        return
    }

    c.JSON(http.StatusCreated, model.AuthResponse{Token: token, User: *user})
}

func (h *AuthHandler) Login(c *gin.Context) {
    var req model.LoginRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    user, err := h.repo.FindByEmail(req.Email)
    if err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Email atau password salah"})
        return
    }

    if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Email atau password salah"})
        return
    }

    token, err := generateToken(user.UserID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal buat token"})
        return
    }

    c.JSON(http.StatusOK, model.AuthResponse{Token: token, User: *user})
}

// Ganti fungsi generateToken di auth_handler.go
func generateToken(userID string) (string, error) {
    claims := jwt.MapClaims{
        "user_id": userID,
        "exp":     time.Now().Add(7 * 24 * time.Hour).Unix(),
    }
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString([]byte(os.Getenv("JWT_SECRET")))
}