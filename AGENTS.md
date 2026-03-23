# Agent Guidelines for RubyOnRailsTest

## Build / Lint / Test Commands

```bash
# Install dependencies
bundle install

# Run all tests
bin/rails test

# Run a single test file
bin/rails test test/models/post_test.rb
bin/rails test test/controllers/posts_controller_test.rb

# Run a specific test by name
bin/rails test test/models/post_test.rb -n test_validations

# Run system tests
bin/rails test:system

# Run linting (RuboCop)
bin/rubocop

# Auto-fix linting issues
bin/rubocop -a

# Security audit
bin/brakeman
bin/bundler-audit

# Database operations
bin/rails db:migrate
bin/rails db:rollback
bin/rails db:seed
bin/rails db:reset

# Start server
bin/rails server
```

## Code Style Guidelines

### Ruby / Rails Style (Omakase)

This project uses [rubocop-rails-omakase](https://github.com/rails/rubocop-rails-omakase). Key conventions:

**Formatting:**
- Use double quotes for strings: `"string"` not `'string'`
- Indent with 2 spaces (no tabs)
- Max line length: 120 characters
- Trailing commas in multi-line arrays/hashes
- No parentheses for method calls without arguments

**Naming:**
- `snake_case` for variables, methods, files
- `CamelCase` for classes, modules
- `SCREAMING_SNAKE_CASE` for constants
- `snake_case` for database tables and columns

**Syntax:**
- Use `class << self` for class methods, not `self.method`
- Prefer `alias_method` over `alias`
- Use `&.` safe navigation operator
- Use `%i[]` for symbol arrays, `%w[]` for string arrays

### Rails Conventions

**Models:** (`app/models/`)
```ruby
class Post < ApplicationRecord
  # Associations first
  belongs_to :user
  has_many :comments, dependent: :destroy
  
  # Then validations
  validates :title, presence: true, length: { minimum: 5 }
  validates :content, presence: true
  
  # Then scopes
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Then callbacks
  before_save :normalize_title
  
  # Then methods
  def summary
    content.truncate(100)
  end
  
  private
  
  def normalize_title
    self.title = title.titleize
  end
end
```

**Controllers:** (`app/controllers/`)
- Keep controllers thin, models fat
- Use `before_action` for shared setup
- Strong parameters required for mass assignment
- Instance variables (`@post`) pass data to views

```ruby
class PostsController < ApplicationController
  before_action :set_post, only: %i[show edit update destroy]
  
  def index
    @posts = Post.all
  end
  
  private
  
  def set_post
    @post = Post.find(params.expect(:id))
  end
  
  def post_params
    params.expect(post: [:title, :content, :published])
  end
end
```

**Views:** (`app/views/`)
- Use ERB syntax: `<%= %>` for output, `<% %>` for logic
- Partial names start with underscore: `_form.html.erb`
- Use Rails helpers: `link_to`, `form_with`, `image_tag`
- No heavy logic in views - use helpers or decorators

**Routes:** (`config/routes.rb`)
```ruby
resources :posts  # Generates all 7 RESTful routes
resources :comments, only: [:create, :destroy]  # Limit routes
root "posts#index"  # Set homepage
```

**Database:**
- Use migrations for schema changes
- Index foreign keys: `add_reference :comments, :post, null: false, foreign_key: true`
- Use `null: false` for required fields
- Use `default: value` for default values

### Testing (Minitest)

**Test Structure:**
```ruby
require "test_helper"

class PostTest < ActiveSupport::TestCase
  # Fixtures automatically loaded (test/fixtures/*.yml)
  setup do
    @post = posts(:one)
  end
  
  test "should validate presence of title" do
    post = Post.new(title: "", content: "Content")
    assert_not post.valid?
    assert_includes post.errors[:title], "can't be blank"
  end
  
  test "should create post" do
    assert_difference("Post.count") do
      Post.create!(title: "Valid Title", content: "Content")
    end
  end
end
```

**Controller Tests:**
```ruby
class PostsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get posts_url
    assert_response :success
    assert_select "h1", "Posts"  # Check HTML content
  end
  
  test "should create post" do
    assert_difference("Post.count") do
      post posts_url, params: { post: { title: "New", content: "Body" } }
    end
    assert_redirected_to post_url(Post.last)
  end
end
```

**Fixtures:** (`test/fixtures/`)
```yaml
one:
  title: "First Post"
  content: "This is the content"
  published: true
  created_at: <%= Time.now %>
```

### Error Handling

- Let Rails handle 404s (RecordNotFound) - don't rescue in controllers
- Use `rescue_from` in ApplicationController for app-wide errors
- Validate at model level, display errors in forms:

```erb
<% if post.errors.any? %>
  <div class="errors">
    <% post.errors.full_messages.each do |msg| %>
      <p><%= msg %></p>
    <% end %>
  </div>
<% end %>
```

### Import Guidelines

- Standard library: `require "json"`
- Gems: already loaded via Bundler
- Project files: rely on Rails autoloading (no explicit require)
- Place custom code in `lib/` - it's autoloaded

### Git Workflow

```bash
# Before committing
bin/rubocop
bin/rails test
bin/brakeman
```

## Project Structure

```
app/
  controllers/    # Handle HTTP requests
  models/         # Business logic & database
  views/          # ERB templates
  helpers/        # View helper methods
  assets/         # CSS, JS, images
config/
  routes.rb       # URL routing
  database.yml    # Database config
db/
  migrate/        # Database migrations
  schema.rb       # Current schema
test/
  controllers/    # Controller tests
  models/         # Model tests
  fixtures/       # Test data
  system/         # Integration tests
```

## Important Notes

- **Rails 8.1** with SQLite3 database
- **Propshaft** asset pipeline (not Sprockets)
- **Hotwire** enabled (Turbo + Stimulus)
- **Solid** adapters: solid_cache, solid_queue, solid_cable
- Tests run in parallel by default
- Always run migrations before testing new features
