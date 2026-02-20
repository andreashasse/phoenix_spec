defmodule Example.Types do
  defmodule User do
    use Spectral

    defstruct [:id, :name, :email]

    spectral(
      title: "User",
      description: "A user resource",
      examples_function: {__MODULE__, :examples, []}
    )

    @type t :: %User{
            id: non_neg_integer() | nil,
            name: String.t(),
            email: String.t() | nil
          }

    def examples do
      [
        %User{id: 1, name: "Alice", email: "alice@example.com"},
        %User{id: 2, name: "Bob", email: "bob@example.com"}
      ]
    end
  end

  defmodule UserInput do
    use Spectral

    defstruct [:name, :email]

    spectral(
      title: "UserInput",
      description: "Input for creating or updating a user",
      examples_function: {__MODULE__, :examples, []}
    )

    @type t :: %UserInput{
            name: String.t(),
            email: String.t()
          }

    def examples do
      [
        %UserInput{name: "Alice", email: "alice@example.com"}
      ]
    end
  end

  defmodule Error do
    use Spectral

    defstruct [:message]

    spectral(
      title: "Error",
      description: "An error response",
      examples_function: {__MODULE__, :examples, []}
    )

    @type t :: %Error{message: String.t()}

    def examples do
      [
        %Error{message: "User not found"}
      ]
    end
  end
end
