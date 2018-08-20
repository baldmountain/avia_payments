defmodule SnitchPayments.Gateway.PayuBiz do
  @moduledoc """
  Module to expose utilities and functions for the payemnt
  gateway `payubiz`.
  """

  alias SnitchPayments.PaymentMethodCode
  alias SnitchPayments.Response.HostedPayment

  @behaviour SnitchPayments.Gateway

  @credentials [:merchant_key, :salt]
  @test_url "https://test.payu.in/_payment"
  @live_url "https://secure.payu.in/_payment"

  @doc """
  Returns a list of credentials.

  The `credentials` provided by a `paubiz`
  to a seller on account creation are required while
  performing a transaction.
  """
  @spec credentials() :: list
  def credentials do
    @credentials
  end

  @doc """
  Returns the `payment code` for the gateway.

  The given module implements functionality for
  payubiz as `hosted payment`. The code is returned
  for the same.
  > See
   `SnitchPayments.PaymentMethodCodes`
  """
  @spec payment_code() :: String.t()
  def payment_code do
    PaymentMethodCode.hosted_payment()
  end

  @doc """
  Parses the `params` supplied and returns a
  `HostedPayment.t()` struct as response.
  """
  @spec parse_response(map) :: HostedPayment.t()
  def parse_response(params) do
    params = filter_payubiz_params(params)
    Map.merge(%HostedPayment{}, params)
  end


  @doc """
  Returns the `test` and `live` `urls` for payubiz
  hosted payment.
  """
  @spec get_url() :: map
  def get_url do
    %{
      test_url: @test_url,
      live_url: @live_url
    }
  end

  defp filter_payubiz_params(params) do
    %{
      transaction_id: params["mihpayid"],
      payment_source: params["source"],
      raw_response: params,
      status: params["status"],
      order_id: String.to_integer(params["order_id"]),
      payment_id: String.to_integer(params["payment_id"])
    }
  end
end
