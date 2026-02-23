defmodule TestUser do
  use Spectral

  defstruct [:id, :name, :email]

  spectral(title: "User", description: "A user resource")

  @type t :: %TestUser{
          id: non_neg_integer() | nil,
          name: String.t(),
          email: String.t() | nil
        }
end

defmodule TestUserInput do
  use Spectral

  defstruct [:name, :email]

  spectral(title: "UserInput", description: "Input for creating a user")

  @type t :: %TestUserInput{
          name: String.t(),
          email: String.t()
        }
end

defmodule TestError do
  use Spectral

  defstruct [:message]

  spectral(title: "Error", description: "An error response")
  @type t :: %TestError{message: String.t()}
end
