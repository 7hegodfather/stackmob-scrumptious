package com.stackmob.scrumptious;

import com.stackmob.sdk.model.StackMobUser;

//We create a specialized subclass of StackMobUser for use in our app.
public class User extends StackMobUser{
	
	public User(String username) {
        super(User.class, username);	
    }
}
