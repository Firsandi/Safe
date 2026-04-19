package main

import (
    "fmt"
    "log"
    "os"
    "time"

    "github.com/gin-contrib/cors"
    "github.com/gin-gonic/gin"
    "github.com/jmoiron/sqlx"
    _ "github.com/lib/pq"

    "safe-backend/internal/handler"
    "safe-backend/internal/repository"
)

func main() {
    // Tunggu DB siap (penting saat pertama kali docker-compose up)
    var db *sqlx.DB
    var err error
    dsn := fmt.Sprintf(
        "host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
        os.Getenv("DB_HOST"), os.Getenv("DB_PORT"),
        os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
        os.Getenv("DB_NAME"),
    )
    for i := 0; i < 10; i++ {
        db, err = sqlx.Connect("postgres", dsn)
        if err == nil {
            break
        }
        log.Printf("DB belum siap, coba lagi... (%d/10)", i+1)
        time.Sleep(2 * time.Second)
    }
    if err != nil {
        log.Fatalf("Gagal koneksi ke DB: %v", err)
    }
    defer db.Close()

    // Wire dependencies
    userRepo := repository.NewUserRepository(db)
    authHandler := handler.NewAuthHandler(userRepo)

    // Router
    r := gin.Default()

    // CORS — biar Flutter bisa akses
    r.Use(cors.New(cors.Config{
        AllowOrigins: []string{"*"},
        AllowMethods: []string{"GET", "POST", "PUT", "DELETE"},
        AllowHeaders: []string{"Origin", "Content-Type", "Authorization"},
    }))

    // Test route biar bisa dicek di browser
    r.GET("/", func(c *gin.Context) {
        c.JSON(200, gin.H{"status": "Safe Backend is Running!"})
    })

    api := r.Group("/api")
    {
        api.POST("/register", authHandler.Register)
        api.POST("/login", authHandler.Login)
    }

    port := os.Getenv("PORT")
    log.Printf("Safe backend jalan di :%s", port)
    r.Run(":" + port)
}