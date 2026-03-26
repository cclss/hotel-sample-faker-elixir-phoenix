defmodule FakrWeb.Router do
  use FakrWeb, :router

  import FakrWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FakrWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug FakrWeb.Plugs.CORS
    plug FakrWeb.Plugs.RateLimit
  end

  # Landing page + health
  scope "/", FakrWeb do
    pipe_through :browser
    get "/", PageController, :home
  end

  # Health check — no rate limiting, no CORS needed
  get "/health", FakrWeb.HealthController, :index

  # Public API endpoints (JSON + CORS)
  scope "/", FakrWeb do
    pipe_through :api
    get "/@:username/:collection_slug/openapi.json", OpenApiController, :show
    options "/@:username/:collection_slug/api/*path", ApiController, :options
    get "/@:username/:collection_slug/api/:resource_slug", ApiController, :index
    get "/@:username/:collection_slug/api/:resource_slug/:id", ApiController, :show
  end

  # Swoosh mailbox preview — Plug.Swoosh.MailboxPreview returns 404
  # when swoosh local storage is disabled, so this is safe to always mount.
  scope "/dev" do
    pipe_through :browser
    forward "/mailbox", Plug.Swoosh.MailboxPreview
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:fakr, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: FakrWeb.Telemetry
    end
  end

  ## Authentication routes

  scope "/", FakrWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{FakrWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      live "/dashboard", DashboardLive, :index
      live "/collections/new", CollectionLive.Form, :new
      live "/collections/:id", CollectionLive.Show, :show
      live "/collections/:collection_id/resources/:id", ResourceLive.Show, :show
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", FakrWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{FakrWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new

      # Public pages
      live "/explore", ExploreLive, :index
      live "/@:username/:collection_slug", CollectionShowLive, :show
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
