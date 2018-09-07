# Programming with Types
## 1. What is a Type System?
The set of rules used by a programming language to define, detect, and prevent illegal program states.

This is done by assigning types to constructs, like functions, variables, or expressions, and using those types to model constraints on those constructs.

Examples of types, using Haskell's syntax, are:
- `String`, a string
- `(Integer, Integer)`, a pair of elements, each an integer
- `String -> Integer`, a function which takes a string as input, and returns an integer

Type systems can be dynamic, and checked at runtime, like in Ruby:

```ruby
> 1 + "test"
TypeError (String can't be coerced into Integer)
```

Or they can be static, and checked at compile time, as in Haskell.

For example, given a file `static-example.hs`:
```haskell
add :: Integer -> Integer -> Integer
add x y = x + y

main = putStrLn . show $ add 5 "test"
```

We can compile it:
```haskell
❯ ghc static-example.hs
[1 of 1] Compiling Main             ( static-example.hs, static-example.o )

static-example.hs:4:32: error:
    • Couldn't match expected type ‘Integer’ with actual type ‘[Char]’
    • In the second argument of ‘add’, namely ‘"test"’
      In the second argument of ‘($)’, namely ‘add 5 "test"’
      In the expression: putStrLn . show $ add 5 "test"
  |
4 | main = putStrLn . show $ add 5 "test"
  |                                ^^^^^^
```

Every language has a type system, though some languages have less permissive type systems
than others.

In Javascript:
```javascript
> {} + []
0
```

In Elixir:
```elixir
iex(1)> {} + []
** (ArithmeticError) bad argument in arithmetic expression: {} + []
    :erlang.+({}, [])
```

Regardless of the strength of the type system you're working with, this talk aims to demonstrate the value of thinking in terms of types and their relationships with each other.

## 2. Why do I care?
Most people think that the value of a strong type system is in catching programmer error early, by preventing basic bugs like dereferencing null, or adding a string to a number.

This is a common misconception.

Type systems instead provide a language for modeling complex domains as simpler models that capture business requirements, security concerns, and data invariants in a clear, concise way.

More than anything else, a strong type system allows you to encode these rules in a manner which becomes enforceable by the compiler.

Elixir's type system is weaker than I'd like, but by approaching software design from a type-first perspective, you are always able to gain the benefits of exploring and refining your domain model, regardless of the programming language being used.

## 3. Algebraic Data Types
### i. Sum and Product Types
A product type is either a tuple, or a record.

Historical Note: Elixir used to have a native record type, but a few years ago Erlang implemented maps, which have more or less replaced records entirely. In real code, I'd recommend sticking to structs wherever possible, as pattern matching off of the type of the struct allows you to perform some level of type checking at runtime.

Elixir:
```elixir
@type coordinate :: {integer, integer}

@type person :: %{
  name: String.t(),
  age: integer()
}
```

Haskell:
```haskell
data Coordinate = Coordinate Integer Integer deriving (Show)

data Person = Person { name :: String
                     , age :: Integer}
```

A sum type is a tagged union, and represents the choice of one type out of many.

Elixir:
```elixir
@type color :: :red | :green | :blue
```

Haskell:
```haskell
data Color = Red | Green | Blue deriving (Show)
```

Oftentimes, product types can be pronounced as `AND`, and sum types can be pronounced as `OR`.

Algebraic Data Types are composite types made up of the composition of product types and sum types.

### ii. Trees Interlude
A classic example of ADTs is an especially elegant representation of binary trees.

Elixir:
```elixir
@type tree :: :leaf | {:node, integer, tree(), tree()}
```

Haskell:
```haskell
data Tree = Leaf | Node Integer Tree Tree deriving (Show)
```

These are recursive ADTs. Essentially, a `Tree` is either a `Leaf`, or it is a `Node`, with an `Integer` value, and two instances of `Tree`: one for each of the left and right subtrees.

For example, the following tree:
```
      0
    /   \
   1     2
```

Can be represented in Elixir, as:
```elixir
{:node,0,
  {:node, 1,
    :leaf,
    :leaf},
  {:node, 2,
    :leaf,
    :leaf}}
```

or in Haskell, as:
```haskell
Node 0 (Node 1 Leaf Leaf) (Node 2 Leaf Leaf)
```

We can easily traverse this structure now, by recursively pattern matching against the `Tree`, and handling the sum type:

```elixir
defmodule Tree do
  def map(tree, f) do
    case tree do
      :leaf ->
        :leaf
      {:node, value, left, right} ->
        {:node, f.(value), map(left, f), map(right, f)}
    end
  end
end

tree =
  {:node,0,
    {:node, 1,
      :leaf,
      :leaf},
    {:node, 2,
      :leaf,
      :leaf}}

Tree.map(tree, fn val -> val + 1 end)
```

Or in Haskell:
```haskell
data Tree = Leaf | Node Integer Tree Tree deriving (Show)

tree_map :: Tree -> (Integer -> Integer) -> Tree
tree_map Leaf f = Leaf
tree_map (Node value left right) f = Node (f value) (tree_map left f) (tree_map right f)
```

```haskell
> t = Node 0 (Node 1 Leaf Leaf) (Node 2 Leaf Leaf)
> tree_map t (+ 1)
Node 1 (Node 2 Leaf Leaf) (Node 3 Leaf Leaf)
```

This is a cool example, but it doesn't demonstrate the ability to encode constraints into the type system. Before we get there, we need to know about the `Maybe` ADT.

### iii. Optional Types
Languages like Haskell don't have any concept of `nil` or `null`, and the concept of an uninhabited value needs to be encoded into the type system as an explicit type.

In most statically typed functional languages, a type named `Maybe` is used to represent optional types. It's a parameterized sum type with two constructors, one representing a value, and the other representing the absence of a value.

```haskell
data Maybe a = Nothing | Just a
```

Let's put everything we just learned into action.

## 4. Impossible States
What's wrong with this design?

```haskell
data User = User { username :: String
                 , name :: String
                 , phoneNumber :: String
                 , emailAddress :: String
                 , emailVerified :: Boolean
                 , paymentType :: String
                 , paypalId :: String
                 , stripeId :: String }
```

Plenty.

First off, `name` is an optional field, but there's no way to know that from the design!

```haskell
data User = User { username :: String
                 , name :: Maybe String
                 , phoneNumber :: String
                 , emailAddress :: String
                 , emailVerified :: Boolean
                 , paymentType :: String
                 , paypalId :: String
                 , stripeId :: String }
```

Also, a `User` is only supposed to have one contact method: either a `phoneNumber` or an `emailAddress`, but not both. What does it mean for a user to have a `phoneNumber` set, but have `emailVerified` set to true? I'm not sure, but it'd be nice if that weren't possible in the first place.

```haskell
data ContactInfo = PhoneNumber String
                 | EmailAddress { address :: String
                                , verified :: Boolean }

data User = User { username :: String
                 , name :: Maybe String
                 , contactInfo :: ContactInfo
                 , paymentType :: String
                 , paypalId :: String
                 , stripeId :: String }
```

Email addresses actually have a few rules associated with them though. First off, we should never send mail to an unverified email address. Second of all, whenever an email address is changed, it should become unverified.

```haskell
data UnverifiedEmail = UnverifiedEmail String
data VerifiedEmail = VerifiedEmail String

data EmailContactInfo = Unverified UnverifiedEmail
                      | Verified VerifiedEmail

data ContactInfo = PhoneNumber String
                 | EmailContactInfo

data User = User { username :: String
                , name :: Maybe String
                , contactInfo :: ContactInfo
                , paymentType :: String
                , paypalId :: String
                , stripeId :: String }

sendEmail :: VerifiedEmail -> <some result>
sendEmail email = ...

newEmail :: String -> UnverifiedEmail
newEmail email -> UnverifiedEmail email

verifyEmail :: UnverifiedEmail -> VerifiedEmail
verifyEmail email = VerifiedEmail email

setEmail :: User -> String -> User
setEmail user newEmailAddress = user { contactInfo = EmailContactInfo (Unverified newEmailAddress) }
```

Almost there! Now we just need to clean up the `paymentType` field. You can't tell from the design, but it's actually possible for someone to have paid by invoice. Oops!

```haskell
data PaymentMethod = Invoice
                   | PayPal { id :: String }
                   | Stripe { id :: String }

...

data User = User { username :: String
                , name :: Maybe String
                , contactInfo :: ContactInfo
                , paymentMethod :: PaymentMethod

...

chargeUser User { paymentMethod = Invoice } = doNothing
chargeUser User { paymentMethod = (Paypal paypal) } = handlePaypal paypal
chargeUser User { paymentMethod = (Stripe stripe) } = handleStripe stripe
```

Beautiful. Now simply by looking at the definition of a `User`, many of the domain requirements of the data are made clear, including which fields are optional, which are mutually exclusive, and even the relationships between types and their capabilities.

Furthermore, even though Elixir isn't nearly as expressive as Haskell, we can still capture most of these sorts of rules:

```elixir
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
```

It's a bit wordier, but it works, and it still nicely models the domain.

## 5. Modeling Failures
Another place where ADTs are especially helpful, is in modeling failure and success states.

Imagine that you're building a chat client that fetches the conversation history, asynchronously, from an API, and then renders it. Sometimes the fetch takes a noticeably long time, and so you decide to model this data like so:

```haskell
data ChatHistory = ChatHistory { messages :: [String], loading :: Boolean }

initialChatHistory = ChatHistory { messages = [], loading = false }
```

What's wrong with this?

1) If you don't remember to check the loading flag, every time, you'll just render an empty conversation until the data is fetched, and then the UI will "jump" into its fully rendered state.

2) This model handles the success case, but has no concept of any of the other states. How do you differentiate between data that is still being loaded, and data whose associated requests have timed out? Is there a distinction between data that is currently loading, and data that hasn't yet been requested?

These are all things we can model with the type system!

```haskell
data RemoteData e a = NotRequested
                    | Loading
                    | Failure e
                    | Success a

data ChatHistory = ChatHistory (RemoteData Http.Error [String])
```

Now, by matching against all of the type constructors, every time (something a strong type system will even enforce!), you can guarantee that you will address every possible case, every time.

Furthermore, we've defined a type that can be reused for ALL types of remote data, by parameterizing it with the errors and data they relate to.

This pattern is incredibly common in functional-reactive frontend applications, like those built with Elm, Reason, or Bucklescript.

## 6. Types as Security
### i. Cross-Site Scripting
Pretend you're writing a templating language for a web framework. Obviously you'd like to avoid cross-site scripting vulnerabilities wherever possible. Normally you'd do that by providing a function to escape user input, and hoping that consumers of your library always remember to use it. Consider the following:

```haskell
data UserInput = Unsafe String
               | Escaped String

escape :: UserInput -> UserInput
escape (Unsafe input) = Escaped (htmlEscape input)
escape (Escaped input) = Escaped input

interpolate :: Template -> UserInput -> Document
interpolate t (Unsafe input) = interpolate t (escape input)
interpolate t (Escaped input) = ...
```

Now, not only is it not possible to ever render unescaped user input to the template, but the type system also enforces that you won't accidentally double escape user input!

This is a pattern used in nearly every functional, statically typed web framework. In fact, even though Elixir is dynamically typed, Phoenix does almost exactly this, behind the scenes!
https://hexdocs.pm/phoenix_html/Phoenix.HTML.Safe.html

Furthermore, you can extend the same ideas to offer compile-time protection against other classes of vulnerabilities, like SQL injection, memory corruption, and information disclosures.

### ii. Information Disclosure
Consider the problem of disclosing private information.

```haskell
data PublicInformation = PublicInformation String
data PrivateInformation = PrivateInformation String

data TemplateVariable a = TemplateVariable String a

data UnprivilegedView = UnprivilegedView { template :: String
                                         , variables :: [TemplateVariable PublicInformation]}

data PrivilegedView = PrivilegedView { template :: String
                                     , publicVariables :: [TemplateVariable PublicInformation]
                                     , privateVariables :: [TemplateVariable PrivateInformation] }

data View = Privileged PrivilegedView
          | Unprivileged UnprivilegedView
```

It's a quick and hacky example, but it succinctly captures the idea of privileged and unprivileged views, with a compile time constraint that unprivileged views can only ever contain public information.

## 7. You get the gist
I could go over examples of domain modeling and cool applications of type systems for hours, but I should probably wrap this up. The main thing I'm hoping for people to get out of this is that there's a lot more to type systems than people usually let on. Used properly, a strong type system should enable you to express compile-time constraints that usually end up being relegated to compile-time checks.

I think that when people complain that type systems just get in the way of coding it means that they're thinking about type systems in the wrong way, and aren't taking advantage of the powerful tools at their disposal.

And again, even in a dynamically typed language, by constraining yourself to code that would compile under a stronger type system, you're able to abstract messy real-world data into simpler domain models, and beautifully express complex business logic in very elegant ways.

## 8. Bonus: Other Type Systems!
Haskell has a strong type system, but it doesn't have the strongest. There exist other formulations of type systems that can express constraints not possible in Haskell.

- `Idris` is a dependently typed language, based on Haskell, in which types are first class citizens, and can be used in computations directly
- `Coq` is dependently typed implementation of higher-order type theory, used as an interactive theorem prover
- `Session Types` are a new branch of type theory, used for type checking communication protocols
- `Linear Types`, implemented using linear logic, can be used to type check the management of resources, such as memory allocations, providing compile-time memory safety without the overheard of a tracing garbage collector
- `Pony`, an experiment actor-model based language, models capabilities using its type system to enable the creation of secure systems and model secure information flow

## 9. Further Reading / Watching
- [Making Impossible States Impossible](https://www.youtube.com/watch?v=IcgmSRJHu_8)
- [How Elm Slays a UI Antipattern](http://blog.jenkster.com/2016/06/how-elm-slays-a-ui-antipattern.html)
- [Domain Modeling Made Functional](https://www.youtube.com/watch?v=Up7LcbGZFuo)
- [Type First Development](http://tomasp.net/blog/type-first-development.aspx/)
- [Types and Programming Languages](https://www.cis.upenn.edu/~bcpierce/tapl/)
