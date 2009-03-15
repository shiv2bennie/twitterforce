public class TwitterTestController {

	
	public List<TwitterForce.Status> publicStatuses { 
		get {
			return twit.getPublicStatuses();
		} set; }
		
	public List<TwitterForce.Status> friendStatuses {	get ; set; }
	public List<TwitterForce.Message> messages { get; set; }
	public List<TwitterForce.Message> messagesSent { get; set; }
	public List<TwitterForce.User> followers { get; set; }
	 
	public String newTweet { get; set; }
	public String un { get; set; }
	public String pw { get; set; }
	public String inReplyTo { get; set; }
	
	public TwitterForce.User thisUser { get; set; }
	public Boolean authenticated { get; set; }
	
	private TwitterForce twit;
	
	public TwitterTestController() {
		twit = new TwitterForce();
		un = 'djcarroll@gmail.com';
		authenticated = false; 
	}
	
	public pageReference loadFollowers() {
		followers = twit.myFollowers();
		
		return null;
	}
	
	public pageReference loadFriendsTimeline() {
		friendStatuses = twit.friendsTimeline();
		return null;
	}
	
	public pageReference loadMessages() {
		messages = twit.getReceivedMessages();
		return null;
	}

	public pageReference loadMessagesSent() {
		messagesSent = twit.getSentMessages();
		return null;
	}
	
	public pageReference authCheck() {
		System.debug(LoggingLevel.DEBUG, '\n\nIn authCheck\nun: ' + un + ', pw: ' + pw);
		if (un != null || pw != null) {
			System.debug(LoggingLevel.DEBUG, '\n\nIn authCheck\nun: ' + un + ', pw: ' + pw);
			thisUser = twit.checkCreds(un, pw);
				
			if (thisUser == null) {
				System.debug('\n\nNot Authenticated...');
				authenticated = null;
			} else {
				System.debug('\n\nAuthenticated...');
				loadFriendsTimeline();
				loadMessages();
				loadMessagesSent();
				loadFollowers();
				authenticated = true;
			}
		}
		return null;
	}
	
	public pageReference doTweet() {
		twit.tweet(newTweet, inReplyTo);
		newTweet = null;
		inReplyTo = null;
		return null;
	}

	public pageReference doMessage() {
		twit.sendMessage(newTweet, inReplyTo);
		newTweet = null;
		inReplyTo = null;
		return null;
	}
}