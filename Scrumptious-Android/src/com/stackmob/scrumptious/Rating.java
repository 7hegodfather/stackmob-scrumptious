package com.stackmob.scrumptious;

import com.stackmob.sdk.api.StackMobFile;
import com.stackmob.sdk.model.StackMobModel;

public class Rating extends StackMobModel {
	
	private String meal;
	private int rating;
	private String place;
	private String comment;
	private StackMobFile photo;
	
	public Rating(String meal, int rating, String place, String comment) {
		super(Rating.class);
		
		this.meal = meal;
		this.rating = rating;
		this.place = place;
		this.comment = comment;
	}

	public String getMeal() {
		return meal;
	}

	public void setMeal(String meal) {
		this.meal = meal;
	}

	public int getRating() {
		return rating;
	}

	public void setRating(int rating) {
		this.rating = rating;
	}

	public String getPlace() {
		return place;
	}

	public void setPlace(String place) {
		this.place = place;
	}

	public String getComment() {
		return comment;
	}

	public void setComment(String comment) {
		this.comment = comment;
	}
	
	public void setPhoto(StackMobFile photo) {
        this.photo = photo;
    }
 
    public StackMobFile getPhoto() {
        return photo;
    }
}
	
