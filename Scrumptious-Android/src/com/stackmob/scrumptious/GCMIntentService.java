package com.stackmob.scrumptious;

import android.content.Context;
import android.content.Intent;
import android.widget.Toast;

import com.google.android.gcm.GCMBaseIntentService;
import com.stackmob.sdk.callback.StackMobNoopCallback;
import com.stackmob.sdk.push.StackMobPush;
import com.stackmob.sdk.push.StackMobPushToken;
import com.stackmob.sdk.push.StackMobPushToken.TokenType;

public class GCMIntentService extends GCMBaseIntentService {
	
	/*
	 * This entire class is dedicated to handling push messages
	 */

	private String regId;

	public GCMIntentService() {
		super(MainActivity.SENDER_ID);
	}

	@Override
	protected void onError(Context ctx, String errorId) {
		Toast.makeText(ctx, "Got a error " + errorId, Toast.LENGTH_LONG).show();
	}

	@Override
	protected void onMessage(Context ctx, Intent arg1) {
		Toast.makeText(ctx, "Got a message!", Toast.LENGTH_LONG).show();

	}

	@Override
	protected void onRegistered(Context ctx, String regId) {
		this.regId = regId;
		PushRegistrationIDHolder holder = new PushRegistrationIDHolder(ctx);
		holder.setID(regId);

	}

	@Override
	protected void onUnregistered(Context arg0, String arg1) {
		StackMobPush.getPush().removePushToken(new StackMobPushToken(regId, TokenType.Android), new StackMobNoopCallback());
	}

}
