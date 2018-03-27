defmodule SunshinesBattleacademy.Web.Router do
  use SunshinesBattleacademy.Web, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", SunshinesBattleacademy.Web do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", PageController, :index)
  end

  # Other scopes may use custom stacks.
  # scope "/api", SunshinesBattleacademy.Web do
  #   pipe_through :api
  # end
end
