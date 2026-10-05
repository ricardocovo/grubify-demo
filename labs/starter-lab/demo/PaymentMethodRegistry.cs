namespace GrubifyApi;

public static class PaymentMethodRegistry
{
    private static readonly IReadOnlyDictionary<string, string> GatewayCodes =
        new Dictionary<string, string>
        {
            ["credit-card"] = "card",
            ["digital-wallet"] = "wallet",
            ["cash-on-delivery"] = "cash"
        };

    public static bool IsSupported(string paymentMethod)
    {
        return GatewayCodes.ContainsKey(paymentMethod);
    }

    public static string GetGatewayCode(string paymentMethod)
    {
        Console.WriteLine($"PaymentMethodRegistry resolving payment method '{paymentMethod}'");
        if (!GatewayCodes.TryGetValue(paymentMethod, out var code))
        {
            throw new ArgumentException($"Unknown payment method: '{paymentMethod}'", nameof(paymentMethod));
        }

        return code;
    }
}
