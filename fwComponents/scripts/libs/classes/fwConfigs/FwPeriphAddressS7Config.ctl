/**
 * @file FwPeriphAddressS7Config.ctl
 * @brief Defines the FwPeriphAddressS7Config class and its methods.
 */

#uses "classes/fwStdLib/FwException"
#uses "classes/fwConfigs/FwPeriphAddressS7Connection.ctl"
#uses "classes/fwConfigs/FwPeriphAddressS7RedundancyControl.ctl"
#uses "classes/fwConfigs/FwPeriphAddressS7ConnectionTSPPExtras.ctl"

class FwPeriphAddressS7Connection;
class FwPeriphAddressS7RedundancyControl;

/**
 * @class FwPeriphAddressS7Config
 * @brief Manages S7 peripheral configurations.
 *
 * This class provides an interface for handling S7 configurations.
 *
 * @section Usage
 *
 * - <b>Initialization:</b> Instantiate the class with the desired configuration name.
 *   @code
 *   FwPeriphAddressS7Config myS7Config("PLC_TEST");
 *   @endcode
 *
 * - <b>Query Configuration:</b> Retrieve the current settings using getter methods.
 *   @code
 *   bool tsppEnabled = myS7Config.isTspp();
 *   @endcode
 *
 * - <b>Modify Configuration:</b> Update settings using setter methods.
 *   @code
 *   myS7Config.setRedundant(true);
 *   @endcode
 *
 * - <b>Apply Changes:</b> Save the modifications by calling the apply() method.
 *   @code
 *   myS7Config.apply();
 *   @endcode
 */
class FwPeriphAddressS7Config
{
    /**
     * @brief Constructor initializes config.
     * @param configName Config name.
     * @param systemName System name, optional.
     */
    public FwPeriphAddressS7Config(string configName, string systemName = getSystemName())
    {
        assertConfigExists(configName, systemName);

        m_name = configName;
        m_dp = getDp(configName, systemName);

        // Update all common config
        load();

        // Create the connection configuration
        m_firstDeviceConnection = new FwPeriphAddressS7Connection(m_dp);
        // The first connection to the first device is always configurable, even if it empty in the beginning
        m_firstDeviceConnection.setConfigurable(true);

        // The second connection is for the redundant device
        // If in the future we want to support dual connection per device this logic should change
        m_redundantDeviceConnection = new FwPeriphAddressS7Connection(m_dp + ".ReduCP");

        // If the device is configurable, it means we are in the redundant device scenario
        m_redundant = m_redundantDeviceConnection.isConfigurable();

        // Set the object for the configuration of redundant properties
        m_redundancyControlConfig = new FwPeriphAddressS7RedundancyControl(m_dp);
        m_redundancyControlConfig.setConfigurable(m_redundant);

        // Trigger an update of TSPP, using the setter with the value received by load
        // Done at the end, to make sure the objects exists
        setTspp(m_tspp);
    }

    /**
     * @brief Check that the name is valid
     */
    private static assertValidName(string configName)
    {
        FwException::assert(!configName.isEmpty(), "Trying to create a S7 Config without name");
        FwException::assert(nameCheck(configName)==0, "Trying to create a S7 Config with invalid name");
    }

    /**
     * @brief Splits received DPEs and values.
     * @return Mapping of DPEs and values.
     */
    private static mapping splitDpesAndValues(...)
    {
        mapping result;
        result["dpes"] = makeDynString();
        result["values"] = makeDynAnytype();

        va_list parameters;

        int parametersLen = va_start(parameters);

        for (int i = 1; i <= parametersLen; i++) {
            dyn_string payload = va_arg(parameters);
            FwException::assertDynNotEmpty(payload, "The received payload number " + i + " is empty");
            int payloadCount = payload.count();
            FwException::assert(payloadCount % 2 == 0, "The received payload number " + i + " constains odd number of elements");
            for (int j=1; j <= payloadCount; j++) {
                if (j%2) // Odd
                    result["dpes"].append(payload[j]);
                else // Even
                    result["values"].append(payload[j]);
            }
        }
        va_end(parameters);
        return result;
    }

    /**
     * @brief Applies configuration.
     */
    public void apply()
    {
        mapping result = splitDpesAndValues(prepareDataToSave(),
                                            m_firstDeviceConnection.prepareDataToSave(),
                                            m_redundantDeviceConnection.prepareDataToSave(),
                                            m_redundancyControlConfig.prepareDataToSave());
        dpSetWait(result["dpes"], result["values"]);
        FwException::checkLastError();
    }

    /**
     * @brief Checks if config exists.
     * @param configName Config name.
     * @param systemName System name.
     */
    private static void assertConfigExists(string configName, string systemName)
    {
        FwException::assert(configExists(configName, systemName), "The requested system name/config name: " +
                            systemName + "/" + configName + " does not exists or it is not S7_Conn type");
    }

    /**
     * @brief Loads configuration.
     */
    private void load()
    {
        // Get all common bits
        dpGet(m_dp + ".SetInvalidBit", m_invalidBit,
              m_dp + ".UseTSPP", m_tspp,
              m_dp + ".AlarmActive", m_alarmActive,
              m_dp + ".EnableDiagnostics", m_diagnosticsEnabled,
              m_dp + ".DrvNumber", m_driverNumber);
        FwException::checkLastError();
    }

    /**
     * @brief Prepares a dyn_string with DPEs and values to save.
     * @return dyn_string with dpes and values.
     */
    private dyn_string prepareDataToSave()
    {
        return makeDynString(m_dp + ".SetInvalidBit", m_invalidBit,
                             m_dp + ".UseTSPP", m_tspp,
                             m_dp + ".AlarmActive", m_alarmActive,
                             m_dp + ".EnableDiagnostics", m_diagnosticsEnabled,
                             m_dp + ".DrvNumber", m_driverNumber);

    }

    /**
    * @brief Checks if the config of a given name and system exists.
    * @param configName Config name.
    * @param systemName System name, optional.
    * @return True if exists, false otherwise.
    */
    public static bool configExists(string configName, string systemName = getSystemName())
    {
        string dp = getDp(configName, systemName);
        return dpExists(dp) && dpTypeName(dp) == "_S7_Conn";
    }

    /**
     * @brief Creates a new config.
     * @param configName Config name.
     * @param systemName System name, optional.
     * @return Pointer to the new FwPeriphAddressS7Config.
     */
    public static shared_ptr<FwPeriphAddressS7Config> createConfig(string configName, string systemName = getSystemName())
    {
        assertValidName(configName);
        dpCreate("_" + configName, "_S7_Conn", getSystemId(systemName));
        FwException::checkLastError();
        return new FwPeriphAddressS7Config(configName, systemName);
    }

    /**
     * @brief Deletes a config.
     * @param configName Config name.
     * @param systemName System name, optional.
     */
    public static void deleteConfig(string configName, string systemName = getSystemName())
    {
        assertConfigExists(configName, systemName);
        dpDelete(getDp(configName, systemName));
        FwException::checkLastError();
    }

    /**
     *  @brief Returns the first device connection.
     *  @return Shared pointer to the first FwPeriphAddressS7Connection object.
     */
    public shared_ptr<FwPeriphAddressS7Connection> getFirstDeviceConnection()
    {
        return m_firstDeviceConnection;
    }

    /**
     * @brief Returns the redundant device connection if it's configurable.
     * @return Shared pointer to the redundant FwPeriphAddressS7Connection object or nullptr.
    */
    public shared_ptr<FwPeriphAddressS7Connection> getRedundantDeviceConnection()
    {
        if (m_redundantDeviceConnection.isConfigurable())
            return m_redundantDeviceConnection;
        return nullptr;
    }

    /**
     * @brief Set alarm status.
     */
    public void setAlarmActive(bool alarmActive)
    {
        m_alarmActive = alarmActive;
    }

    /**
     * @brief Check if alarm is active.
     * @return Boolean value of alarm status.
     */
    public bool isAlarmActive()
    {
        return m_alarmActive;
    }

    /**
     * @brief Set the invalid bit flag.
     */
    public void setInvalidBit(bool invalidBit)
    {
        m_invalidBit = invalidBit;
    }

    /**
     * @brief Get the invalid bit flag.
     * @return True if invalid bit is set, false otherwise.
     */
    public bool isInvalidBit()
    {
        return m_invalidBit;
    }

    /**
     * @brief Enable or disable diagnostics.
     */
    public void setDiagnosticsEnabled(bool diagnosticsEnabled)
    {
        m_diagnosticsEnabled = diagnosticsEnabled;
    }

    /**
     * @brief Check if diagnostics is enabled.
     * @return True if diagnostics is enabled, false otherwise.
     */
    public bool isDiagnosticsEnabled()
    {
        return m_diagnosticsEnabled;
    }

    /**
     * @brief Sets the TSPP flag and updates connections.
     * @param tspp The new value of the TSPP flag.
     */
    public void setTspp(bool tspp)
    {
        m_tspp = tspp;
        m_firstDeviceConnection.setTspp(tspp);
        m_redundantDeviceConnection.setTspp(tspp);
    }

    /**
     * @brief Gets the current status of the TSPP flag.
     * @return True if TSPP is enabled, false otherwise.
     */
    public bool isTspp()
    {
        return m_tspp;
    }

    /**
     * @brief Sets the redundant flag and updates configurations accordingly.
     * @param redundant The new value of the redundant device flag.
     */
    public void setRedundant(bool redundant)
    {
        m_redundant = redundant;
        m_redundantDeviceConnection.setConfigurable(redundant);
        m_redundancyControlConfig.setConfigurable(redundant);
    }

    /**
     * @brief Gets the current status of the redundant device flag.
     * @return True if device is set to be redundant, false otherwise.
     */
    public bool isRedundant()
    {
        return m_redundant;
    }


    /**
     * @brief Gets the name of the config.
     * @return The name of the config.
     */
    public string getName()
    {
        return m_name;
    }

    /**
     * @brief Gets the driver number associated with the config.
     * @return The driver number.
     */
    public int getDriverNumber()
    {
        return m_driverNumber;
    }

    /**
     * @brief Sets the driver number for the config.
     * @param driverNumber The new driver number.
     */
    public void setDriverNumber(int driverNumber)
    {
        m_driverNumber = driverNumber;
    }

    /**
     * @brief Constructs a datapoint string based on name and system name.
     * @param configName The name part of the datapoint.
     * @param systemName The system name part of the datapoint.
     * @return The constructed datapoint string.
     */
    private static string getDp(string configName, string systemName)
    {
        return systemName + "_" + configName;
    }

    /**
     * @brief Data point.
     */
    private string m_dp;

    /**
     * @brief Config name.
     */
    private string m_name;

    /**
     * @brief Driver number.
     */
    private int m_driverNumber = 0;

    /**
     * @brief Flag for invalid bit.
     */
    private bool m_invalidBit = false;

    /**
     * @brief Flag for alarm status.
     */
    private bool m_alarmActive = false;

    /**
     * @brief Flag for diagnostics enablement.
     */
    private bool m_diagnosticsEnabled = false;

    /**
     * @brief Flag for TSPP enablement.
     */
    private bool m_tspp = false;

    /**
     * @brief Flag for redundant device enablement.
     */
    private bool m_redundant = false;

// Room for improvement m_redundantConnectionFirstDevice and m_redundantConnectionRedundantConnection not implemented

    /**
     * @brief First device connection.
     */
    private shared_ptr<FwPeriphAddressS7Connection> m_firstDeviceConnection = nullptr;

    /**
     * @brief Redundant device connection.
     */
    private shared_ptr<FwPeriphAddressS7Connection> m_redundantDeviceConnection = nullptr;

    /**
     * @brief Redundancy control device.
     */
    private FwPeriphAddressS7RedundancyControl m_redundancyControlConfig = nullptr;
};
