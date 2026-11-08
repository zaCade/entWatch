#if defined entWatch_class_config_included
	#endinput
#endif

#define entWatch_class_config_included

methodmap CConfig < StringMap
{
	public CConfig()
	{
		StringMap stringMap = new StringMap();

		stringMap.SetString("sName",            "");
		stringMap.SetString("sShort",           "");
		stringMap.SetString("sColor",           "");

		stringMap.SetValue("iConfigID",         0);
		stringMap.SetValue("iHammerID",         0);

		stringMap.SetValue("bShowMessages",     false);
		stringMap.SetValue("bShowInterface",    false);

		stringMap.SetValue("hButtons",          new ArrayList());
		stringMap.SetValue("hTriggers",         new ArrayList());

		return view_as<CConfig>(stringMap);
	}

	public bool GetName(char[] sBuffer, int iLength)
	{
		return this.GetString("sName", sBuffer, iLength);
	}

	public bool SetName(const char[] sBuffer)
	{
		return this.SetString("sName", sBuffer);
	}

	public bool GetShort(char[] sBuffer, int iLength)
	{
		return this.GetString("sShort", sBuffer, iLength);
	}

	public bool SetShort(const char[] sBuffer)
	{
		return this.SetString("sShort", sBuffer);
	}

	public bool GetColor(char[] sBuffer, int iLength)
	{
		return this.GetString("sColor", sBuffer, iLength);
	}

	public bool SetColor(const char[] sBuffer)
	{
		return this.SetString("sColor", sBuffer);
	}

	property int iConfigID
	{
		public get()
		{
			int iValue;
			if (this.GetValue("iConfigID", iValue))
				return iValue;

			return -1;
		}
		public set(int iValue)
		{
			this.SetValue("iConfigID", iValue);
		}
	}

	property int iHammerID
	{
		public get()
		{
			int iValue;
			if (this.GetValue("iHammerID", iValue))
				return iValue;

			return -1;
		}
		public set(int iValue)
		{
			this.SetValue("iHammerID", iValue);
		}
	}

	property bool bShowMessages
	{
		public get()
		{
			bool bValue;
			if (this.GetValue("bShowMessages", bValue))
				return bValue;

			return false;
		}
		public set(bool bValue)
		{
			this.SetValue("bShowMessages", bValue);
		}
	}

	property bool bShowInterface
	{
		public get()
		{
			bool bValue;
			if (this.GetValue("bShowInterface", bValue))
				return bValue;

			return false;
		}
		public set(bool bValue)
		{
			this.SetValue("bShowInterface", bValue);
		}
	}

	property ArrayList hButtons
	{
		public get()
		{
			ArrayList hValue;
			if (this.GetValue("hButtons", hValue))
				return hValue;

			return null;
		}
		public set(ArrayList hValue)
		{
			this.SetValue("hButtons", hValue);
		}
	}

	property ArrayList hTriggers
	{
		public get()
		{
			ArrayList hValue;
			if (this.GetValue("hTriggers", hValue))
				return hValue;

			return null;
		}
		public set(ArrayList hValue)
		{
			this.SetValue("hTriggers", hValue);
		}
	}

	public void Delete()
	{
		if (this.hButtons != null)
		{
			for (int iConfigButtonID; iConfigButtonID < this.hButtons.Length; iConfigButtonID++)
			{
				StringMap hConfigButton = this.hButtons.Get(iConfigButtonID);

				delete hConfigButton;
			}

			delete this.hButtons;
		}

		if (this.hTriggers != null)
		{
			for (int iConfigTriggerID; iConfigTriggerID < this.hTriggers.Length; iConfigTriggerID++)
			{
				StringMap hConfigTrigger = this.hTriggers.Get(iConfigTriggerID);

				delete hConfigTrigger;
			}

			delete this.hTriggers;
		}

		delete this;
	}
}
