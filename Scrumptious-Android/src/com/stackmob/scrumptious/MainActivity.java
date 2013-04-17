package com.stackmob.scrumptious;

import java.util.ArrayList;
import java.util.List;

import org.apache.http.HttpResponse;
import org.apache.http.NameValuePair;
import org.apache.http.client.HttpClient;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.params.HttpConnectionParams;
import org.json.JSONObject;

import android.content.Intent;
import android.os.Bundle;
import android.os.Looper;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentTransaction;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;

import com.facebook.Request;
import com.facebook.Response;
import com.facebook.Session;
import com.facebook.SessionState;
import com.facebook.UiLifecycleHelper;
import com.facebook.model.GraphUser;
import com.stackmob.android.sdk.common.StackMobAndroid;
import com.stackmob.sdk.api.StackMob;
import com.stackmob.sdk.api.StackMobOptions;
import com.stackmob.sdk.callback.StackMobModelCallback;
import com.stackmob.sdk.exception.StackMobException;

public class MainActivity extends FragmentActivity {

	public static String SENDER_ID = "YOUR_SENDER_ID";

	private static final int SPLASH = 0;
	private static final int SELECTION = 1;
	private static final int SETTINGS = 2;
	private static final int FRAGMENT_COUNT = SETTINGS + 1;

	private MenuItem settings;

	private Fragment[] fragments = new Fragment[FRAGMENT_COUNT];

	private boolean isResumed = false;

	private ScrumptiousApplication scrumptiousApplication;

	//private static final String TAG = MainActivity.class.getCanonicalName();

	private UiLifecycleHelper uiHelper;
	private Session.StatusCallback callback = new Session.StatusCallback() {
		@Override
		public void call(final Session session, final SessionState state,
				final Exception exception) {

			if (state.isOpened()
					&& !scrumptiousApplication.getUser().isLoggedIn()) {

				// Check whether the user is logged into StackMob
				// Grab user Id from facebook
				Request request = Request.newMeRequest(session,
						new Request.GraphUserCallback() {
							@Override
							public void onCompleted(GraphUser graphUser,
									Response response) {
								if (graphUser != null) {
									scrumptiousApplication.setUser(new User(
											graphUser.getUsername()));
									// Run our helper method to create a user
									loginWithFacebook(session, state, exception);
								}
							}
						});
				Request.executeBatchAsync(request);
			} else if (state.isClosed()
					&& scrumptiousApplication.getUser().isLoggedIn()) {
				// If the session state is closed:
				// Show the login fragment

				// Once the FB session is closed, log the User out of StackMob
				scrumptiousApplication.getUser().logout(
						new StackMobModelCallback() {
							@Override
							public void success() {
								// the call succeeded
								onSessionStateChange(session, state, exception);
							}

							@Override
							public void failure(StackMobException e) {
								// the call failed
							}
						});
			} else {
				onSessionStateChange(session, state, exception);
			}
		}
	};

	
	// This is use with push 
	/*
	private final StackMobCallback standardToastCallback = new StackMobCallback() {

		@Override
		public void success(String responseBody) {
			threadAgnosticToast(MainActivity.this, "response: " + responseBody,
					Toast.LENGTH_SHORT);
			Log.i(TAG, "request succeeded with " + responseBody);
		}

		@Override
		public void failure(StackMobException e) {
			threadAgnosticToast(MainActivity.this, "error: " + e.getMessage(),
					Toast.LENGTH_SHORT);
			Log.i(TAG, "request had exception " + e.getMessage());
		}
	};
	*/
	 
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		uiHelper = new UiLifecycleHelper(this, callback);
		uiHelper.onCreate(savedInstanceState);

		setContentView(R.layout.main);

		scrumptiousApplication = (ScrumptiousApplication) this.getApplication();

		postToImpressionEndpoint();

		// Initialize the StackMob SDK
		StackMobAndroid.init(getApplicationContext(), 1, "YOUR_PUBLIC_KEY");

		// Initialize the StackMob SDK with OAuth (for push)
		/*
		 StackMobAndroid.init(this.getApplicationContext(),
		 StackMob.OAuthVersion.One, 1, "YOUR_PUBLIC_KEY",
		 "YOUR_PRIVATE_KEY");
		*/
		
		// Turn on logging
		StackMob.getStackMob().getSession().getLogger().setLogging(true);

		
		// Register for GCM Push 
		/*
		try {
			GCMRegistrar.checkDevice(this);
			GCMRegistrar.checkManifest(this);
			final String regId = GCMRegistrar.getRegistrationId(this);
			if (regId.equals("")) {
				registerForPush();
			} else {
				Log.v(TAG, "Already registered");
			}
		} catch (UnsupportedOperationException e) {
			Log.w(TAG, "This device doesn't support gcm. Push will not work");
		}
		*/

		FragmentManager fm = getSupportFragmentManager();
		fragments[SPLASH] = fm.findFragmentById(R.id.splashFragment);
		fragments[SELECTION] = fm.findFragmentById(R.id.selectionFragment);
		fragments[SETTINGS] = fm.findFragmentById(R.id.userSettingsFragment);

		FragmentTransaction transaction = fm.beginTransaction();
		for (int i = 0; i < fragments.length; i++) {
			transaction.hide(fragments[i]);
		}
		transaction.commit();
	}

	private void postToImpressionEndpoint() {

		Thread t = new Thread() {

			public void run() {
				Looper.prepare(); // For Preparing Message Pool for the child
									// Thread
				HttpClient client = new DefaultHttpClient();
				HttpConnectionParams.setConnectionTimeout(client.getParams(),
						10000); // Timeout Limit
				HttpResponse response;
				JSONObject payload = new JSONObject();

				try {

					payload.put("resource", "stackmob_stackmob");
					payload.put("appid", "131456347033972");
					payload.put("version", "android_1.0.0");

					List<NameValuePair> params = new ArrayList<NameValuePair>(2);
					params.add(new BasicNameValuePair("plugin",
							"featured_resources"));
					params.add(new BasicNameValuePair("payload", payload
							.toString()));

					HttpPost httppost = new HttpPost(
							"https://www.facebook.com/impression.php");
					httppost.setEntity(new UrlEncodedFormEntity(params));
					httppost.setHeader("Content-type", "application/json");
					httppost.setHeader("Accept", "application/json");

					// Create a new HttpClient and Post Header
					HttpClient httpclient = new DefaultHttpClient();
					response = httpclient.execute(httppost);

					/* Checking response */
					if (response != null) {
						Log.i("Facebook Endpoint", response.getStatusLine()
								.toString());
					}

				} catch (Exception e) {
					e.printStackTrace();
				}

				Looper.loop(); // Loop in the message queue
			}
		};

		t.start();
	}

	
	// Push registration methods 
	/*
	private void registerForPush() {
		GCMRegistrar.register(this, SENDER_ID);
	}

	private PushRegistrationIDHolder getRegistrationIDHolder() {
		return new PushRegistrationIDHolder(MainActivity.this);
	}
	*/

	private void showFragment(int fragmentIndex, boolean addToBackStack) {
		FragmentManager fm = getSupportFragmentManager();
		FragmentTransaction transaction = fm.beginTransaction();
		for (int i = 0; i < fragments.length; i++) {
			if (i == fragmentIndex) {
				transaction.show(fragments[i]);
			} else {
				transaction.hide(fragments[i]);
			}
		}
		if (addToBackStack) {
			transaction.addToBackStack(null);
		}
		transaction.commit();
	}

	@Override
	public void onResume() {
		super.onResume();
		uiHelper.onResume();
		isResumed = true;
	}

	@Override
	public void onPause() {
		super.onPause();
		uiHelper.onPause();
		isResumed = false;
	}

	@Override
	public void onActivityResult(int requestCode, int resultCode, Intent data) {
		super.onActivityResult(requestCode, resultCode, data);
		uiHelper.onActivityResult(requestCode, resultCode, data);
	}

	@Override
	public void onDestroy() {
		super.onDestroy();
		uiHelper.onDestroy();
	}

	@Override
	protected void onSaveInstanceState(Bundle outState) {
		super.onSaveInstanceState(outState);
		uiHelper.onSaveInstanceState(outState);
	}

	private void onSessionStateChange(Session session, SessionState state,
			Exception exception) {
		// Only make changes if the activity is visible
		if (isResumed) {
			FragmentManager manager = getSupportFragmentManager();
			// Get the number of entries in the back stack
			int backStackSize = manager.getBackStackEntryCount();
			// Clear the back stack
			for (int i = 0; i < backStackSize; i++) {
				manager.popBackStack();
			}
			if (state.isOpened()) {
				// If the session state is open:
				// Show the authenticated fragment
				showFragment(SELECTION, false);
			} else if (state.isClosed()) {
				// If the session state is closed:
				// Show the login fragment
				showFragment(SPLASH, false);
			}
		}
	}

	@Override
	protected void onResumeFragments() {
		super.onResumeFragments();
		Session session = Session.getActiveSession();

		if (session != null && session.isOpened()) {
			// if the session is already open,
			// try to show the selection fragment
			showFragment(SELECTION, false);
		} else {
			// otherwise present the splash screen
			// and ask the user to login.
			showFragment(SPLASH, false);
		}
	}

	@Override
	public boolean onPrepareOptionsMenu(Menu menu) {
		// only add the menu when the selection fragment is showing
		if (fragments[SELECTION].isVisible()) {
			if (menu.size() == 0) {
				settings = menu.add(R.string.settings);
			}
			return true;
		} else {
			menu.clear();
			settings = null;
		}
		return false;
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		if (item.equals(settings)) {
			showFragment(SETTINGS, true);
			return true;
		}
		return false;
	}

	// Our login method
	private void loginWithFacebook(final Session session,
			final SessionState state, final Exception exception) {

		
		// Here we register for push notifications 
		/*
		try {
			user.registerForPush(new StackMobPushToken(
					getRegistrationIDHolder().getID()), standardToastCallback);
		} catch (Exception e) {
			threadAgnosticToast(MainActivity.this,
					"no registration ID currently stored", Toast.LENGTH_SHORT);
		}
		*/
		scrumptiousApplication.getUser().loginWithFacebook(
				session.getAccessToken(), true,
				scrumptiousApplication.getUser().getUsername(),
				new StackMobOptions(), new StackMobModelCallback() {
					@Override
					public void success() {

						onSessionStateChange(session, state, exception);
					}

					@Override
					public void failure(StackMobException e) {

					}
				});
	}

	
	// This method is used for push 
	/*
	private void threadAgnosticToast(final Context ctx, final String txt,
			final int duration) {
		runOnUiThread(new Runnable() {

			@Override
			public void run() {
				Toast.makeText(ctx, txt, duration).show();
			}
		});
	}
	*/

}
