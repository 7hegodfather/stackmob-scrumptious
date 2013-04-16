package com.stackmob.scrumptious;

import java.util.List;

import android.app.Application;

import com.facebook.model.GraphPlace;
import com.facebook.model.GraphUser;

public class ScrumptiousApplication extends Application {
	
	private List<GraphUser> selectedUsers;
	private GraphPlace selectedPlace;
	private Rating rating = null;
	private User user = new User(null);

	public List<GraphUser> getSelectedUsers() {
	    return selectedUsers;
	}

	public void setSelectedUsers(List<GraphUser> users) {
	    selectedUsers = users;
	}

	public GraphPlace getSelectedPlace() {
	    return selectedPlace;
	}

	public void setSelectedPlace(GraphPlace place) {
	    this.selectedPlace = place;
	}

	public Rating getRating() {
		return rating;
	}

	public void setRating(Rating rating) {
		this.rating = rating;
	}

	public User getUser() {
		return user;
	}

	public void setUser(User user) {
		this.user = user;
	}
	
}
