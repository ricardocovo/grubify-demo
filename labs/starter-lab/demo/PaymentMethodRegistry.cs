namespace GrubifyApi;

public static class PaymentMethodRegistry
{
    private static readonly IReadOnlyDictionary<string, string> GatewayCodes =
        new Dictionary<string, string>
        {
            ["credit_card"] = "card",
            ["digital-wallet"] = "wallet",
            ["cash-on-delivery"] = "cash"
        };

    public static string GetGatewayCode(string paymentMethod)
    {
        Console.WriteLine($"PaymentMethodRegistry resolving payment method '{paymentMethod}'");
        return GatewayCodes[paymentMethod];
    }
}
