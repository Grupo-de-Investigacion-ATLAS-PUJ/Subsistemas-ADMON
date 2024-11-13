#uses "classes/fwStdLib/FwException"

class FwPeriphAddressS7Config;
class FwPeriphAddressS7Connection;

/**
 * @class FwPeriphAddressS7ConnectionTSPPExtras
 * @brief Manages TSPP extra configurations for S7 Connections.
 */
class FwPeriphAddressS7ConnectionTSPPExtras
{
    friend FwPeriphAddressS7Connection;

    /**
     * @brief Constructor for the class.
     * @param config Configuration string.
     */
    private FwPeriphAddressS7ConnectionTSPPExtras(string config = "")
    {
        if (sizeof(config) == 0) // Nothing to do, keep default values
            return;
        dyn_string parts = config.split(".");
        FwException::assert(parts.count() == 6, "Fatal error: TSPPExtras does not contain 6 numbers separated by dot");
        m_connId = parts.at(0);
        m_cpId = parts.at(1);
        m_pcRack = parts.at(2);
        m_pcSlot = parts.at(3);
        m_pcId = parts.at(4);
    }

    /**
     * @brief Prepares a string the values to save in the format of WinCC OA.
     * @return string with dpes and values.
     */
    private string prepareDataToSave()
    {
        if (m_configurable)
            return m_connId + "." + m_cpId + "." + m_pcRack + "." + m_pcSlot + "." + m_pcId + ".0";
        return "";
    }

    /**
     * @brief Sets Connection ID.
     * @param connId Connection ID.
     */
    public void setConnId(int connId)
    {
        m_connId = connId;
    }

    /**
     * @brief Gets Connection ID.
     * @return Connection ID.
     */
    public int getConnId()
    {
        return m_connId;
    }

    /**
     * @brief Sets the CpId.
     * @param cpId CpId value.
     */
    public void setCpId(int cpId)
    {
        m_cpId = cpId;
    }

    /**
     * @brief Gets the CpId.
     * @return CpId value.
     */
    public int getCpId()
    {
        return m_cpId;
    }

    /**
     * @brief Sets the PC rack number.
     * @param pcRack PC rack number.
     */
    public void setPcRack(int pcRack)
    {
        m_pcRack = pcRack;
    }

    /**
     * @brief Gets the PC rack number.
     * @return PC rack number.
     */
    public int getPcRack()
    {
        return m_pcRack;
    }

    /**
     * @brief Sets the PC slot number.
     * @param pcSlot PC slot number.
     */
    public void setPcSlot(int pcSlot)
    {
        m_pcSlot = pcSlot;
    }

    /**
     * @brief Gets the PC slot number.
     * @return PC slot number.
     */
    public int getPcSlot()
    {
        return m_pcSlot;
    }

    /**
     * @brief Sets the PcId.
     * @param pcId PcId value.
     */
    public void setPcId(int pcId)
    {
        m_pcId = pcId;
    }

    /**
     * @brief Gets the PcId.
     * @return PcId value.
     */
    public int getPcId()
    {
        return m_pcId;
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
    * @brief Gets the configurable status.
    * @return Configurable status
    */
    private bool isConfigurable()
    {
        return m_configurable;
    }

    /**
     * @brief Indicates whether the object is configurable or not.
     */
    private bool m_configurable = false;

    /**
     * @brief Connection ID.
     */
    private int m_connId = 0;

    /**
     * @brief CpId (Communication Processor ID).
     */
    private int m_cpId = 0;

    /**
     * @brief Rack number of the PC.
     */
    private int m_pcRack = 0;

    /**
     * @brief Slot number of the PC.
     */
    private int m_pcSlot = 0;

    /**
     * @brief PcId: PC-ID.
     */
    private int m_pcId = 0;
};
