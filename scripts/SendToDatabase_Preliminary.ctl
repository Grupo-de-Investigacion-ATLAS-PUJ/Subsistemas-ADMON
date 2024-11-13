// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file scripts/SendToDatabase_Preliminary.ctl
  @copyright $copyright
  @author Sebastian Vergara
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)

//--------------------------------------------------------------------------------
// Variables and Constants

//--------------------------------------------------------------------------------
/**
*/
main()
{
    // Connect the script to the Voltage_Value data point so it runs when the value changes
    dpConnect("dist_11:ELMB/Can01/ELMB1/AI/voltage_0", "sendToInflux");
}

// Function that gets triggered when Voltage_Value changes
void sendToInflux()
{
    string influx_url = "http://localhost:8086/write?db=your_database";
    string measurement = "Voltage_Value";
    string voltage_dp = "dist_11:ELMB/Can01/ELMB1/AI/voltage_0";

    // Get the current value of Voltage_Value
    dyn_float voltage_values;
    dpGet(voltage_dp, voltage_values);

    if (dynlen(voltage_values) > 0)
    {
        float voltage_value = voltage_values[0]; // Assuming single value

        // Prepare the data in Line Protocol format
        string data = measurement + ",datapoint=" + voltage_dp + " value=" + voltage_value;

        // Send the data via HTTP POST to InfluxDB
        dyn_string headers = makeDynString("Content-Type: text/plain");
        int result = httpPost(influx_url, data, headers);

        // Debugging output
        DebugN("Data sent to InfluxDB:", data);
        DebugN("HTTP POST result:", result);
    }
    else
    {
        DebugN("No data retrieved for", voltage_dp);
    }
}
