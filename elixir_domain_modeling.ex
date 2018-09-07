defmodule User do
  defstruct [
    :username,
    :name,
    :contact_info,
    :payment_method
  ]

  @type t :: %__MODULE__{
    username: String.t(),
    name: String.t() | nil,
    contact_info: ContactInfo.t(),
    payment_method: PaymentMethod.t()
  }
end

defmodule ContactInfo do
  defmodule PhoneNumber do
    defstruct [:number]

    @type t :: %__MODULE__{
      number: String.t
    }

    @spec send_sms(t(), String.t()) :: :ok
    def send_sms(%__MODULE__{} = phone_number, message) do
      # ...
    end
  end

  defmodule EmailContactInfo do
    defmodule VerifiedEmail do
      defstruct [:email]

      @type t :: %__MODULE__{
        email: String.t
      }

      @spec send_email(t(), String.t()) :: :ok
      def send_email(%__MODULE__{email: email}, message) do
        # send_email
      end
    end

    defmodule UnverifiedEmail do
      defstruct [:email]

      @type t :: %__MODULE__{
        email: String.t
      }

      @spec verify(t()) :: VerifiedEmail.t()
    end

    defstruct [:email]

    @type t :: %__MODULE__{
      email: VerifiedEmail.t() | UnverifiedEmail.t()
    }

    @spec new(String.t()) :: t()
    def new(email) do
      %__MODULE__{
        email: %UnverifiedEmail{email: email}
      }
    end

    @spec verify(t()) :: t()
    def verify(%__MODULE__{email: %UnverifiedEmail{} = email}) do
      %__MODULE__{
        email: UnverifiedEmail.verify(email)
      }
    end

    @spec send_email(t(), String.t()) :: :ok
    def send_email(%__MODULE__{email: %VerifiedEmail{} = email}, message) do
      VerifiedEmail.send_email(email, message)
    end
  end

  @type t :: PhoneNumber.t() | EmailContactInfo.t()

  @spec contact(t(), String.t) :: :ok
  def contact(%PhoneNumber{} = phone_number, message) do
    PhoneNumber.send_sms(phone_number, message)
  end

  def contact(%EmailContactInfo{} = email_contact_info, message) do
    EmailContactInfo.send_email(email_contact_info, message)
  end
end

defmodule PaymentMethod do
  defmodule Invoice do
    defstruct []

    @type t :: %__MODULE__{}
  end

  defmodule Paypal do
    defstruct [:id]

    @type t :: %__MODULE__{
      id: String.t
    }
  end

  defmodule Stripe do
    defstruct [:id]

    @type t :: %__MODULE__{
      id: String.t
    }
  end

  @type t :: Invoice.t() | Paypal.t() | Stripe.t()
end
