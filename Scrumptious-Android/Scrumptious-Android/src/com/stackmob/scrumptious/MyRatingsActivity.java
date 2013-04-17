package com.stackmob.scrumptious;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.app.Dialog;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.RatingBar;
import android.widget.TextView;

import com.facebook.model.OpenGraphAction;
import com.stackmob.sdk.api.StackMob;
import com.stackmob.sdk.api.StackMobQuery;
import com.stackmob.sdk.callback.StackMobCallback;
import com.stackmob.sdk.callback.StackMobQueryCallback;
import com.stackmob.sdk.exception.StackMobException;

public class MyRatingsActivity extends Activity {

	private ListView listView;
	private List<BaseListElement> listElements;
	List<Rating> ratings;
	JSONObject averages;

	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.myratings);

		// Find the list view
		listView = (ListView) findViewById(R.id.ratings_list);

		listView.setOnItemClickListener(new OnItemClickListener() {
			@Override
			public void onItemClick(AdapterView<?> parent, View view,
					int position, long id) {
				// When a rating is selected, we show the detail view
				showDetailView(view, position);

			}
		});

		fetchRatings();
	}

	public void fetchRatings() {

		ScrumptiousApplication scrumptiousApplication = (ScrumptiousApplication) this
				.getApplication();

		Rating.query(
				Rating.class,
				new StackMobQuery().fieldIsEqualTo("sm_owner", "user/"
						+ scrumptiousApplication.getUser().getUsername()),
				new StackMobQueryCallback<Rating>() {
					@Override
					public void success(List<Rating> results) {
						// We've now got a list of all our ratings
						ratings = results;

						getAverageRatings();

						// We reuse the BaseListElement from earlier
						listElements = new ArrayList<BaseListElement>();
						for (Rating rating : ratings) {
							RatingListElement element = new RatingListElement();
							if (rating.getPhoto() != null) {
								element.setPhoto(rating.getPhoto().getS3Url());
							}
							element.setText1(rating.getPlace());
							element.setText2(String.format(getResources()
									.getString(R.string.rating_description),
									rating.getMeal(), rating.getRating()));
							listElements.add(element);
						}

						// Here we update the UI
						runOnUiThread(new Runnable() {
							public void run() {
								// Set the list view adapter
								listView.setAdapter(new ActionListAdapter(
										MyRatingsActivity.this,
										R.id.ratings_list, listElements));
							}
						});

					}

					@Override
					public void failure(StackMobException e) {

					}
				});
	}

	// This method hits our Custom Code endpoint and grabs the average ratings
	public void getAverageRatings() {

		String endpoint = "getaveragerating";
		String places = "";

		for (Rating rating : ratings) {
			places = places.concat(String.format("%s,", rating.getPlace()));
		}

		StackMob.getStackMob()
				.getDatastore()
				.post(endpoint, String.format("{\"places\":\"%s\"}", places),
						new StackMobCallback() {
							@Override
							public void success(String responseBody) {
								try {
									averages = new JSONObject(responseBody);
								} catch (JSONException e) {
									e.printStackTrace();
								}

							}

							@Override
							public void failure(StackMobException e) {

							}
						});
	}

	public void showDetailView(View view, int position) {

		// Grab the rating
		Rating rating = ratings.get(position);

		// custom dialog
		final Dialog dialog = new Dialog(view.getContext());
		dialog.setContentView(R.layout.rating_detail);
		dialog.setTitle("Rating Detail");

		// set the custom dialog components
		ImageView imageView = (ImageView) dialog.findViewById(R.id.imageView);
		if (rating.getPhoto() != null) {
			new DownloadImageTask(imageView).execute(rating.getPhoto()
					.getS3Url());
		}

		TextView rating_place_text = (TextView) dialog
				.findViewById(R.id.rating_place_text);
		rating_place_text
				.setText(String.format("Place: %s", rating.getPlace()));

		TextView rating_meal_text = (TextView) dialog
				.findViewById(R.id.rating_meal_text);
		rating_meal_text.setText(String.format("Meal: %s", rating.getMeal()));

		RatingBar my_rating = (RatingBar) dialog.findViewById(R.id.my_rating);
		my_rating.setRating(rating.getRating());

		TextView avg_rating_text = (TextView) dialog
				.findViewById(R.id.avg_rating_text);
		RatingBar avg_rating = (RatingBar) dialog.findViewById(R.id.avg_rating);
		avg_rating_text.setVisibility(View.GONE);
		avg_rating.setVisibility(View.GONE);

		// If we don't have the the average ratings, we don't show their
		// components
		if (averages != null) {
			avg_rating_text.setVisibility(View.VISIBLE);
			avg_rating.setVisibility(View.VISIBLE);
			try {
				avg_rating.setRating(Float.parseFloat(averages.getString(rating
						.getPlace())));
			} catch (NumberFormatException e) {
				e.printStackTrace();
			} catch (JSONException e) {
				e.printStackTrace();
			}
		}

		TextView rating_comment = (TextView) dialog
				.findViewById(R.id.rating_comment);
		rating_comment.setText(rating.getComment());

		dialog.show();
	}

	// We re-purpose this ListAdapter to show our ratings
	private class ActionListAdapter extends ArrayAdapter<BaseListElement> {
		private List<BaseListElement> listElements;

		public ActionListAdapter(Context context, int resourceId,
				List<BaseListElement> listElements) {
			super(context, resourceId, listElements);
			this.listElements = listElements;
			for (int i = 0; i < listElements.size(); i++) {
				listElements.get(i).setAdapter(this);
			}
		}

		@Override
		public View getView(int position, View convertView, ViewGroup parent) {
			View view = convertView;
			if (view == null) {
				LayoutInflater inflater = (LayoutInflater) MyRatingsActivity.this
						.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
				view = inflater.inflate(R.layout.listitem, null);
			}

			RatingListElement listElement = (RatingListElement) listElements
					.get(position);
			if (listElement != null) {
				ImageView icon = (ImageView) view.findViewById(R.id.icon);
				TextView text1 = (TextView) view.findViewById(R.id.text1);
				TextView text2 = (TextView) view.findViewById(R.id.text2);
				if (listElement.getPhoto() != null) {
					new DownloadImageTask(icon).execute(listElement.getPhoto());
				}
				if (text1 != null) {
					text1.setText(listElement.getText1());
				}
				if (text2 != null) {
					text2.setText(listElement.getText2());
				}
			}
			return view;
		}

	}

	private class RatingListElement extends BaseListElement {

		private String photo;

		public String getPhoto() {
			return photo;
		}

		public void setPhoto(String photo) {
			this.photo = photo;
		}

		public RatingListElement() {
			super(null, null, null, 0);
		}

		@Override
		protected View.OnClickListener getOnClickListener() {
			return null;
		}

		@Override
		protected void populateOGAction(OpenGraphAction action) {

		}

		@Override
		protected void onSaveInstanceState(Bundle bundle) {

		}

		@Override
		protected boolean restoreState(Bundle savedState) {
			return false;
		}
	}

	private class DownloadImageTask extends AsyncTask<String, Void, Bitmap> {
		ImageView bmImage;

		public DownloadImageTask(ImageView bmImage) {
			this.bmImage = bmImage;
		}

		protected Bitmap doInBackground(String... urls) {
			String urldisplay = urls[0];
			Bitmap mIcon11 = null;
			try {
				BitmapFactory.Options options = new BitmapFactory.Options();
				options.inSampleSize = 4;
				InputStream in = new java.net.URL(urldisplay).openStream();
				mIcon11 = BitmapFactory.decodeStream(in, null, options);
			} catch (Exception e) {
				Log.e("Error", e.getMessage());
				e.printStackTrace();
			}
			return mIcon11;
		}

		protected void onPostExecute(Bitmap result) {

			bmImage.setImageBitmap(result);
		}
	}

}
