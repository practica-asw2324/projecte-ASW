# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2024_04_13_134313) do
  create_table "boosts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_boosts_on_post_id"
    t.index ["user_id"], name: "index_boosts_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.string "body"
    t.integer "user_id", null: false
    t.integer "post_id", null: false
    t.integer "comment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at"
    t.index ["comment_id"], name: "index_comments_on_comment_id"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "dislikes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_dislikes_on_post_id"
    t.index ["user_id"], name: "index_dislikes_on_user_id"
  end

  create_table "dislikes_comments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "comment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_id"], name: "index_dislikes_comments_on_comment_id"
    t.index ["user_id"], name: "index_dislikes_comments_on_user_id"
  end

  create_table "likes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_likes_on_post_id"
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "likes_comments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "comment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_id"], name: "index_likes_comments_on_comment_id"
    t.index ["user_id"], name: "index_likes_comments_on_user_id"
  end

  create_table "magazines", force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.string "description"
    t.string "rules"
    t.datetime "created_at", null: false
    t.datetime "updated_at"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_magazines_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.string "body"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at"
    t.integer "magazine_id", null: false
    t.integer "user_id", null: false
    t.index ["magazine_id"], name: "index_posts_on_magazine_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "username"
    t.datetime "created_at", null: false
    t.datetime "updated_at"
  end

  add_foreign_key "boosts", "posts"
  add_foreign_key "boosts", "users"
  add_foreign_key "comments", "comments"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "dislikes", "posts"
  add_foreign_key "dislikes", "users"
  add_foreign_key "dislikes_comments", "comments"
  add_foreign_key "dislikes_comments", "users"
  add_foreign_key "likes", "posts"
  add_foreign_key "likes", "users"
  add_foreign_key "likes_comments", "comments"
  add_foreign_key "likes_comments", "users"
  add_foreign_key "magazines", "users"
  add_foreign_key "posts", "magazines"
  add_foreign_key "posts", "users"
end
