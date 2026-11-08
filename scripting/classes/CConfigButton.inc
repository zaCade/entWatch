#if defined entWatch_class_config_button_included
	#endinput
#endif

#define entWatch_class_config_button_included

methodmap CConfigButton < StringMap
{
	public CConfigButton(CConfig hConfig = null)
	{
		StringMap stringMap = new StringMap();

		stringMap.SetString("sName",            "");
		stringMap.SetString("sOutput",          "");

		stringMap.SetValue("hConfig",           hConfig);

		stringMap.SetValue("iConfigID",         0);
		stringMap.SetValue("iHammerID",         0);
		stringMap.SetValue("iType",             0);
		stringMap.SetValue("iMode",             0);
		stringMap.SetValue("iMaxUses",          0);

		stringMap.SetValue("flButtonCooldown",  0.0);
		stringMap.SetValue("flItemCooldown",    0.0);

		stringMap.SetValue("bShowActivate",     false);
		stringMap.SetValue("bShowCooldown",     false);

		return view_as<CConfigButton>(stringMap);
	}

	public bool GetName(char[] sBuffer, int iLength)
	{
		return this.GetString("sName", sBuffer, iLength);
	}

	public bool SetName(char[] sBuffer)
	{
		return this.SetString("sName", sBuffer);
	}

	public bool GetOutput(char[] sBuffer, int iLength)
	{
		return this.GetString("sOutput", sBuffer, iLength);
	}

	public bool SetOutput(const char[] sBuffer)
	{
		return this.SetString("sOutput", sBuffer);
	}

	property CConfig hConfig
	{
		public get()
		{
			CConfig hValue;
			if (this.GetValue("hConfig", hValue))
				return hValue;

			return null;
		}
		public set(CConfig hValue)
		{
			this.SetValue("hConfig", hValue);
		}
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

	property int iType
	{
		public get()
		{
			int iValue;
			if (this.GetValue("iType", iValue))
				return iValue;

			return -1;
		}
		public set(int iValue)
		{
			this.SetValue("iType", iValue);
		}
	}

	property int iMode
	{
		public get()
		{
			int iValue;
			if (this.GetValue("iMode", iValue))
				return iValue;

			return -1;
		}
		public set(int iValue)
		{
			this.SetValue("iMode", iValue);
		}
	}

	property int iMaxUses
	{
		public get()
		{
			int iValue;
			if (this.GetValue("iMaxUses", iValue))
				return iValue;

			return -1;
		}
		public set(int iValue)
		{
			this.SetValue("iMaxUses", iValue);
		}
	}

	property float flButtonCooldown
	{
		public get()
		{
			float flValue;
			if (this.GetValue("flButtonCooldown", flValue))
				return flValue;

			return -1.0;
		}
		public set(float flValue)
		{
			this.SetValue("flButtonCooldown", flValue);
		}
	}

	property float flItemCooldown
	{
		public get()
		{
			float flValue;
			if (this.GetValue("flItemCooldown", flValue))
				return flValue;

			return -1.0;
		}
		public set(float flValue)
		{
			this.SetValue("flItemCooldown", flValue);
		}
	}

	property bool bShowActivate
	{
		public get()
		{
			bool bValue;
			if (this.GetValue("bShowActivate", bValue))
				return bValue;

			return false;
		}
		public set(bool bValue)
		{
			this.SetValue("bShowActivate", bValue);
		}
	}

	property bool bShowCooldown
	{
		public get()
		{
			bool bValue;
			if (this.GetValue("bShowCooldown", bValue))
				return bValue;

			return false;
		}
		public set(bool bValue)
		{
			this.SetValue("bShowCooldown", bValue);
		}
	}
}
