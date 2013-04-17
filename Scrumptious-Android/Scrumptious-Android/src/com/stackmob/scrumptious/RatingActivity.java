package com.stackmob.scrumptious;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.RatingBar;
import android.widget.RatingBar.OnRatingBarChangeListener;

public class RatingActivity extends Activity {

	private Button rate_button;
	private RatingBar rating_bar;
	private EditText comment_text;

	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.rating);

		rating_bar = (RatingBar) findViewById(R.id.rating_bar);
		rate_button = (Button) findViewById(R.id.rate_button);
		rate_button.setEnabled(false);
		comment_text = (EditText) findViewById(R.id.comment_text);

		rating_bar
				.setOnRatingBarChangeListener(new OnRatingBarChangeListener() {
					public void onRatingChanged(RatingBar ratingBar,
							float rating, boolean fromUser) {

						if (ratingBar.getRating() == 0) {
							rate_button.setEnabled(false);
						} else {
							rate_button.setEnabled(true);
						}
					}
				});

		rate_button.setOnClickListener(new View.OnClickListener() {
			@Override
			public void onClick(View view) {

				Rating rating = new Rating(null, (int) rating_bar.getRating(),
						null, comment_text.getText().toString());

				ScrumptiousApplication scrumptiousApplication = (ScrumptiousApplication) getApplication();
				scrumptiousApplication.setRating(rating);

				setResult(RESULT_OK, null);
				finish();
			}
		});

	}
}
