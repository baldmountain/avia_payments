defmodule SnitchPayments.Gateway.Stripe do
  @moduledoc """
  Module to expose utilities and functions for the payemnt
  gateway `stripe`.
  """
  alias SnitchPayments.PaymentMethodCode
  alias Gringotts, as: Billing
  alias Gringotts.Gateways.Stripe
  alias Gringotts.Address
  alias SnitchPayments.Response.HostedPayment

  @behaviour SnitchPayments.Gateway
  @credentials [:secret_key, :publishable_key]

  @failure_status "failure"
  @success_status "success"

  @doc """
  Returns the preferences for the gateway, at present it is mainly the
  list of credentials.

  These `credentials` refer to one provided by a `stripe` to a seller on
  account creation.

  The credentials consist of
  - `secret key`
  - `publishable key`
  """
  @spec preferences() :: list
  def preferences do
    @credentials
  end

  @doc """
  Returns the `payment code` for the gateway.

  The given module implements functionality for
  stripe as `hosted payment`. The code is returned
  for the same.
  > See
   `SnitchPayments.PaymentMethodCodes`
  """
  def payment_code do
    PaymentMethodCode.hosted_payment()
  end

  @doc """
  Makes a `purchase` request with the supplied inputs.

  `token`: Refers to the token generated by using stripe elemets for making
    the payment.
  `secret`: Refers to secret of the merchant.
  `amount`: Amount for which the payment should be made.
  `params`: A keyword list of extra params that can be sent to stripe for
   making the payment

  To see a list of key words that can be sent, see
  `Gringotts.Gateways.Stripe`

  ### TODO:
   Find an elegant way to handle to set the `secret_key`.
  """
  @spec purchase(String.t(), String.t(), Money.t(), Keyword.t()) :: map
  def purchase(token, secret, amount, params) do
    Application.put_env(:gringotts, Gringotts.Gateways.Stripe, secret_key: secret)
    address = Map.merge(%Address{}, params[:address])
    params = Keyword.put(params, :address, address)
    Billing.purchase(Stripe, amount, token, params)
  end

  def parse_response(%{"error" => _errors} = params) do
    params = stripe_error_response_mapping(params)
    Map.merge(%HostedPayment{}, params)
  end

  def parse_response(params) do
    params = stripe_success_response_mapping(params)
    Map.merge(%HostedPayment{}, params)
  end

  defp stripe_error_response_mapping(params) do
    %{
      transaction_id: params["error"]["charge"],
      payment_source: params["payment_source"],
      raw_response: params,
      status: @failure_status,
      order_id: String.to_integer(params["order_id"]),
      payment_id: String.to_integer(params["payment_id"]),
      error_reason: params["error"]["code"] <> ": " <> params["error"]["message"]
    }
  end

  defp stripe_success_response_mapping(params) do
    %{
      transaction_id: params["id"],
      payment_source: params["payment_source"],
      raw_response: params,
      status: @success_status,
      order_id: String.to_integer(params["order_id"]),
      payment_id: String.to_integer(params["payment_id"]),
      paid: true
    }
  end
end
