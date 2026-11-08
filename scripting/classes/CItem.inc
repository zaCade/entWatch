#if defined entWatch_class_item_included
	#endinput
#endif

#define entWatch_class_item_included

methodmap CItem < StringMap
{
	public CItem(CConfig hConfig = null, int iCreateID = -1)
	{
		StringMap stringMap = new StringMap();

		stringMap.SetValue("hConfig",           hConfig);

		stringMap.SetValue("iCreateID",         iCreateID);
		stringMap.SetValue("iClient",           INVALID_ENT_REFERENCE);
		stringMap.SetValue("iWeapon",           INVALID_ENT_REFERENCE);
		stringMap.SetValue("iState",            EW_ENTITY_STATE_INITIAL);

		stringMap.SetValue("flReadyTime",       0.0);

		stringMap.SetValue("hButtons",          new ArrayList());
		stringMap.SetValue("hTriggers",         new ArrayList());

		return view_as<CItem>(stringMap);
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

	property int iCreateID
	{
		public get()
		{
			int iValue;
			if (this.GetValue("iCreateID", iValue))
				return iValue;

			return -1;
		}
		public set(int iValue)
		{
			this.SetValue("iCreateID", iValue);
		}
	}

	property int iClient
	{
		public get()
		{
			int iValue;
			if (this.GetValue("iClient", iValue))
				return iValue;

			return -1;
		}
		public set(int iValue)
		{
			this.SetValue("iClient", iValue);
		}
	}

	property int iWeapon
	{
		public get()
		{
			int iValue;
			if (this.GetValue("iWeapon", iValue))
				return iValue;

			return -1;
		}
		public set(int iValue)
		{
			this.SetValue("iWeapon", iValue);
		}
	}

	property int iState
	{
		public get()
		{
			int iValue;
			if (this.GetValue("iState", iValue))
				return iValue;

			return -1;
		}
		public set(int iValue)
		{
			this.SetValue("iState", iValue);
		}
	}

	property float flReadyTime
	{
		public get()
		{
			float flValue;
			if (this.GetValue("flReadyTime", flValue))
				return flValue;

			return -1.0;
		}
		public set(float flValue)
		{
			this.SetValue("flReadyTime", flValue);
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
			for (int iItemButtonID; iItemButtonID < this.hButtons.Length; iItemButtonID++)
			{
				StringMap hItemButton = this.hButtons.Get(iItemButtonID);

				delete hItemButton;
			}

			delete this.hButtons;
		}

		if (this.hTriggers != null)
		{
			for (int iItemTriggerID; iItemTriggerID < this.hTriggers.Length; iItemTriggerID++)
			{
				StringMap hItemTrigger = this.hTriggers.Get(iItemTriggerID);

				delete hItemTrigger;
			}

			delete this.hTriggers;
		}

		delete this;
	}
}
