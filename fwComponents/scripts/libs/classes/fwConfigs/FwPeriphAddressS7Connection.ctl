#uses "json"
#uses "classes/fwStdLib/FwException"

class FwPeriphAddressS7ConnectionTSPPExtras;
class FwPeriphAddressS7Config;

enum FwPeriphAddressS7Connection_IE_TCP {
    PG = 0,
    OP = 1,
    TSPP = 3
};

/**
 * @class FwPeriphAddressS7Connection
 * @brief Manages S7 Connections.
 */
class FwPeriphAddressS7Connection
{
    friend FwPeriphAddressS7Config;

    /**
     * @brief Constructor.
     * @param dp Data point.
     */
    private FwPeriphAddressS7Connection(string dp)
    {
        m_dp = dp;
        load();
    }

    /**
     * @brief Loads the connection configuration.
     */
    private void load()
    {
        string jsonAddressPayload;
        int result = dpGet(m_dp + ".Active", m_active,
                           m_dp + ".Address", jsonAddressPayload);

        FwException::checkLastError();

        if (sizeof(jsonAddressPayload) == 0) {
            m_configurable = false;
            m_tsppExtras = new FwPeriphAddressS7ConnectionTSPPExtras();
        } else {
            m_configurable = true;
            loadJsonAddressPayload(jsonAddressPayload);
        }
    }
    private void loadJsonAddressPayload(string jsonAddressPayload)
    {
        if (!json_isValid(jsonAddressPayload))
            FwException::raise("Invalid JSON Payload at: " + m_dp + ".Address");

        mapping addressPayload = jsonDecode(jsonAddressPayload);

        if (addressPayload.contains("IPAddress"))
            m_ipAddress = addressPayload.value("IPAddress");
        else
            FwException::raise("Invalid JSON Payload at: " + m_dp + ".Address. Missing key IPAddress");

        if (addressPayload.contains("Rack"))
            m_rack = addressPayload.value("Rack");
        else
            FwException::raise("Invalid JSON Payload at: " + m_dp + ".Address. Missing key: Rack");

        if (addressPayload.contains("Slot"))
            m_slot = addressPayload.value("Slot");
        else
            FwException::raise("Invalid JSON Payload at: " + m_dp + ".Address. Missing key: Slot");

        if (addressPayload.contains("TimeOut"))
            m_timeout = addressPayload.value("TimeOut");
        else
            FwException::raise("Invalid JSON Payload at: " + m_dp + ".Address. Missing key: TimeOut");

        if (addressPayload.contains("ConnectionType"))
            m_connectionType = addressPayload.value("ConnectionType");
        else
            FwException::raise("Invalid JSON Payload at: " + m_dp + ".Address. Missing key: ConnectionType");

        if (addressPayload.contains("TSPPExtras"))
            m_tsppExtras = new FwPeriphAddressS7ConnectionTSPPExtras(addressPayload.value("TSPPExtras"));
        else
            FwException::raise("Invalid JSON Payload at: " + m_dp + ".Address. TSPPExtras");

        if (addressPayload.contains("ProtocolExtras"))
            m_protocolExtras = addressPayload.value("ProtocolExtras");
        else
            FwException::raise("Invalid JSON Payload at: " + m_dp + ".Address. ProtocolExtras");
    }

    /**
     * @brief Prepares a dyn_string with DPEs and values to save.
     * @return dyn_string with dpes and values.
     */
    private dyn_string prepareDataToSave()
    {
        if (m_configurable) {
            mapping addressPayload;

            addressPayload["IPAddress"] = m_ipAddress;
            addressPayload["Rack"] = m_rack;
            addressPayload["Slot"] = m_slot;
            addressPayload["TimeOut"] = m_timeout;
            addressPayload["ConnectionType"] = m_tspp?FwPeriphAddressS7Connection_IE_TCP::TSPP:m_connectionType;
            addressPayload["TSPPExtras"] = m_tsppExtras.prepareDataToSave();
            addressPayload["ProtocolExtras"] = m_protocolExtras;


            return makeDynString(m_dp + ".Active", m_active,
                                 m_dp + ".Address", jsonEncode(addressPayload));
        }

        return makeDynString(m_dp + ".Active", false,
                             m_dp + ".Address", "");
    }

    /**
     * @brief Sets IP address.
     * @param ipAddress IP address.
     */
    public void setIpAddress(string ipAddress)
    {
        m_ipAddress = ipAddress;
    }

    /**
     * @brief Gets the IP address.
     * @return The IP address.
     */
    public string getIpAddress()
    {
        return m_ipAddress;
    }

    /**
     * @brief Sets the connection type.
     * @param connectionType Connection type.
     */
    public void setConnectionType(FwPeriphAddressS7Connection_IE_TCP connectionType)
    {
        if (!m_tspp && connectionType == FwPeriphAddressS7Connection_IE_TCP::TSPP)
            FwException::raise("Connection type TSPP is not supported for IE_TCP configuration");
        m_connectionType = connectionType;
    }

    /**
     * @brief Gets the connection type.
     * @return The connection type.
     */
    public FwPeriphAddressS7Connection_IE_TCP getConnectionType()
    {
        return m_connectionType;
    }

    /**
     * @brief Sets the rack number.
     * @param rack Rack number.
     */
    public void setRack(int rack)
    {
        m_rack = rack;
    }

    /**
     * @brief Gets the rack number.
     * @return Rack number.
     */
    public int getRack()
    {
        return m_rack;
    }

    /**
     * @brief Sets the slot number.
     * @param slot Slot number.
     */
    public void setSlot(int slot)
    {
        m_slot = slot;
    }

    /**
     * @brief Gets the slot number.
     * @return Slot number.
     */
    public int getSlot()
    {
        return m_slot;
    }

    /**
     * @brief Sets the timeout duration.
     * @param timeout Timeout.
     */
    public void setTimeout(int timeout)
    {
        m_timeout = timeout;
    }

    /**
     * @brief Gets the timeout duration.
     * @return Timeout.
     */
    public int getTimeout()
    {
        return m_timeout;
    }

    /**
     * @brief Checks if configurable.
     * @return True if configurable.
     */
    private bool isConfigurable()
    {
        return m_configurable;
    }

    /**
     * @brief Sets the configurable status.
     * @param configurable Configurable flag.
     */
    private setConfigurable(bool configurable)
    {
        m_configurable = configurable;
    }

    /**
     * @brief Sets the TSPP flag.
     * @param tspp TSPP flag.
     */
    private setTspp(bool tspp)
    {
        m_tspp = tspp;
        m_tsppExtras.setConfigurable(tspp);
        if (m_tspp)
            m_connectionType = FwPeriphAddressS7Connection_IE_TCP::TSPP;
        else
            m_connectionType = FwPeriphAddressS7Connection_IE_TCP::PG;
    }

    /**
     * @brief Checks if configurable.
     * @return The tsppExtras instances if tspp is enabled. Otherwise nullptr.
     */
    public shared_ptr<FwPeriphAddressS7ConnectionTSPPExtras> getTsppExtras()
    {
        if (m_tsppExtras.isConfigurable())
            return m_tsppExtras;
        DebugN(__FUNCTION__, "Requesting TSPP Extras, but TSPP mode is not set, returning nullptr");
        return nullptr;
    }

    /**
     * @brief Sets the active status.
     * @param active Active flag.
     */
    public  void setActive(bool active)
    {
        m_active = active;
    }

    /**
     * @brief Gets the active status.
     * @return True if active.
     */
    public bool isActive()
    {
        return m_active;
    }

    /**
     * @brief Indicates if the connection is configurable.
     */
    private bool m_configurable = false;

    /**
     * @brief Indicates if the connection is active.
     */
    private bool m_active = false;

    /**
     * @brief TSPP flag.
     */
    private bool m_tspp = false;

    /**
     * @brief Data point.
     */
    private string m_dp = "";

    /**
     * @brief IP address.
     */
    private string m_ipAddress = "localhost";

    /**
     * @brief Connection type.
     */
    private FwPeriphAddressS7Connection_IE_TCP m_connectionType = FwPeriphAddressS7Connection_IE_TCP::PG;

    /**
     * @brief Rack number.
     */
    private int m_rack = 0;

    /**
     * @brief Slot number.
     */
    private int m_slot = 0;

    /**
     * @brief Timeout duration.
     */
    private int m_timeout = 5000;

    /**
     * @brief Protocol extras.
     */
    private string m_protocolExtras = "";

    /**
     * @brief TSPP extras.
     */
    private shared_ptr<FwPeriphAddressS7ConnectionTSPPExtras> m_tsppExtras = nullptr;
};
