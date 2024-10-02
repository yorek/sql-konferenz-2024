using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System.Xml;
using System.Xml.Serialization;
using FromBodyAttribute = Microsoft.Azure.Functions.Worker.Http.FromBodyAttribute;
using System.Text.Json;

namespace func
{
    [XmlRoot("PurchaseOrder", Namespace = "http://www.cpandl.com", IsNullable = false)]
    public class PurchaseOrder
    {
        public required Address ShipTo;
        public required string OrderDate;
        /* The XmlArrayAttribute changes the XML element name
         from the default of "OrderedItems" to "Items". */
        [XmlArray("Items")]
        public required OrderedItem[] OrderedItems;
        [XmlElement]
        public decimal SubTotal => OrderedItems.Sum(oi => oi.LineTotal);
        public decimal ShipCost;        
        [XmlElement]
        public decimal TotalCost => SubTotal + ShipCost;
    }

    public class Address
    {
        /* The XmlAttribute instructs the XmlSerializer to serialize the Name
           field as an XML attribute instead of an XML element (the default
           behavior). */
        [XmlAttribute]
        public required string Name;
        public required string Line1;

        /* Setting the IsNullable property to false instructs the
           XmlSerializer that the XML attribute will not appear if
           the City field is set to a null reference. */
        [XmlElement(IsNullable = false)]
        public required string City;
        public required string State;
        public required string Zip;
    }

    public class OrderedItem
    {
        public required string ItemName;
        public required string Description;
        public decimal UnitPrice;
        public int Quantity;
        [XmlElement]
        public decimal LineTotal => UnitPrice * Quantity;
    }

    public record PurchaseOrderId
    {
        public int Id;
    }

    public class PurchaseOrderManager(ILogger<PurchaseOrderManager> logger)
    {
        private readonly ILogger<PurchaseOrderManager> _logger = logger;

        private readonly JsonSerializerOptions _jsonSerializerOptions = new() { IncludeFields = true, PropertyNameCaseInsensitive = true };

        [Function("purchase-order")]
        public async Task<IActionResult> GetPurchaseOrder([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequest req)
        {
            // Read id from query string
            _ = int.TryParse(req.Query["id"].ToString(), out int id);

            // Read from body
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            PurchaseOrderId? poid = string.IsNullOrEmpty(requestBody) ? null : JsonSerializer.Deserialize<PurchaseOrderId>(requestBody, _jsonSerializerOptions);
            if (poid != null)
                id = poid.Id;
            
            _logger.LogInformation($"Returning sample purchase order (id={id}), requested format: {req.Headers.Accept}");

            var po1 = new PurchaseOrder() {
                OrderedItems = [
                    new OrderedItem() {
                        ItemName = "Widget S",
                        Description = "Small widget",
                        UnitPrice = (decimal)5.23,
                        Quantity = 3
                    }
                ],
                ShipTo = new Address() {
                    Name = "Teresa Atkinson",
                    Line1 = "1 Main St.",
                    City = "AnyTown",
                    State = "WA",
                    Zip = "00000"
                },
                OrderDate = DateTime.Now.ToLongDateString(),           
                ShipCost = (decimal)12.51                
            };

            var po2 = new PurchaseOrder() {
                OrderedItems = [
                    new OrderedItem() {
                        ItemName = "Bike Rack",
                        Description = "Small widget",
                        UnitPrice = (decimal)5.23,
                        Quantity = 3
                    }
                ],
                ShipTo = new Address() {
                    Name = "John Doe",
                    Line1 = "2 Ferry St.",
                    City = "Redmond",
                    State = "WA",
                    Zip = "99999"
                },
                OrderDate = DateTime.Now.ToLongDateString(),           
                ShipCost = (decimal)34.00                
            };

            var pos = new List<PurchaseOrder>() { po1, po2 };
            switch (id)
            {
                case >= 1 when id <= pos.Count:
                    return new OkObjectResult(pos[id - 1]);
                case < 0:
                    return new BadRequestObjectResult("Invalid id");
                default:
                    if (id > pos.Count)
                    {
                        return new NotFoundObjectResult("Not found");
                    }
                    else
                    {
                        return new OkObjectResult(pos);
                    }
            }
        }
    }
}
