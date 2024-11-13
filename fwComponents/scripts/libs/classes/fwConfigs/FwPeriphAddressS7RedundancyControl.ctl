class FwPeriphAddressS7Config;

enum FwPeriphAddressS7RedundancyControl_CommandMode {
    COMMAND_TO_ACTIVE = 0,
    COMMAND_TO_BOTH = 1
};

enum FwPeriphAddressS7RedundancyControl_Switch {
    AUTOMATIC = 0,
    DEVICE_1 = 1,
    DEVICE_2 = 2,
    AUTOMATIC_H = 3
};

/**
 * @class FwPeriphAddressS7RedundancyControl
 * @brief Manages redundancy control for S7 devices.
 */
class FwPeriphAddressS7RedundancyControl
{
    friend FwPeriphAddressS7Config;

    /**
     * @brief Constructor for the class.
     * @param dp Data point address.
     */
    private FwPeriphAddressS7RedundancyControl(string dp)
    {
        m_dp = dp + ".ReduControl.CP";
        int result = dpGet(m_dp + ".SpsTag", m_plcTag,
                           m_dp + ".CmdMode", m_commandMode,
                           m_dp + ".Switch", m_switch);
        FwException::checkLastError();
    }

    /**
     * @brief Prepares a dyn_string with DPEs and values to save.
     * @return dyn_string with dpes and values.
     */
    public dyn_string prepareDataToSave()
    {
        if (m_tspp && m_switch == FwPeriphAddressS7RedundancyControl_Switch::AUTOMATIC_H)
            // Automatic-H is not available in TSSP Config, using AUTOMATIC
            m_switch = FwPeriphAddressS7RedundancyControl_Switch::AUTOMATIC;

        if (m_configurable) {
            return makeDynString(m_dp + ".SpsTag", m_plcTag,
                                 m_dp + ".CmdMode", m_commandMode,
                                 m_dp + ".Switch", m_switch);
        }
        return makeDynString(m_dp + ".SpsTag", "",
                             m_dp + ".CmdMode", 0,
                             m_dp + ".Switch", 0);
    }

    /**
     * @brief Sets TSSP flag.
     * @param tspp TSSP value.
     */
    public void setTspp(bool tspp)
    {
        m_tspp = tspp;
    }

    /**
     * @brief Checks if TSSP is enabled.
     * @return True if TSSP is enabled, false otherwise.
     */
    public bool isTspp()
    {
        return m_tspp;
    }

    /// @brief Sets the datapoint string.
    /// @param dp The new datapoint string.
    public void setDp(string dp)
    {
        m_dp = dp;
    }

    /// @brief Gets the current datapoint string.
    /// @return The current datapoint string.
    public string getDp()
    {
        return m_dp;
    }

    /// @brief Sets the command mode for the redundancy control device.
    /// @param commandMode The new command mode.
    public void setCommandMode(int commandMode)
    {
        m_commandMode = commandMode;
    }

    /// @brief Gets the current command mode.
    /// @return The current command mode.
    public int getCommandMode()
    {
        return m_commandMode;
    }

    /// @brief Sets the switch mode for the redundancy control device.
    /// @param switch The new switch mode.
    public void setSwitch(int _switch)
    {
        m_switch = _switch;
    }

    /// @brief Gets the current switch mode.
    /// @return The current switch mode.
    public int getSwitch()
    {
        return m_switch;
    }

    /// @brief Sets the PLC tag address for automatic switching.
    /// @param plcTag The new PLC tag address.
    public void setPlcTag(string plcTag)
    {
        m_plcTag = plcTag;
    }

    /// @brief Gets the current PLC tag address for automatic switching.
    /// @return The current PLC tag address.
    public string getPlcTag()
    {
        return m_plcTag;
    }

    /// @brief Sets the configurable status.
    /// @param configurable The new configurable status.
    private void setConfigurable(bool configurable)
    {
        m_configurable = configurable;
    }

    /// @brief Gets the current configurable status.
    /// @return True if configurable, false otherwise.
    private bool isConfigurable()
    {
        return m_configurable;
    }

    /**
     * @brief Flag indicating if configurable.
     */
    private bool m_configurable = false;

    /**
     * @brief TSSP flag.
     */
    private bool m_tspp = false;

    /**
     * @brief Data Point address.
     */
    private string m_dp = "";

    /**
     * @brief Command mode.
     */
    private FwPeriphAddressS7RedundancyControl_CommandMode m_commandMode = FwPeriphAddressS7RedundancyControl_CommandMode::COMMAND_TO_ACTIVE;

    /**
     * @brief Switch mode.
     */
    private FwPeriphAddressS7RedundancyControl_Switch m_switch = FwPeriphAddressS7RedundancyControl_Switch::AUTOMATIC;

    /**
     * @brief PLC Tag for automatic switching.
     */
    private string m_plcTag = "";
};

// Room for improvement class FwPeriphAddressS7RedundancyControlConnection not implemented
