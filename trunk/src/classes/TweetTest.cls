public class TweetTest {

	private static TwitterForce twitter;
	 
	public static void main() {
		twitter = new TwitterForce();
		TwitterForce.User u = twitter.checkCreds('djcarroll@gmail.com', 'Hailey24');
		System.debug('\n\n' + twitter.getRateLimitStatus());
		//System.debug('\n\n' + twitter.getReceivedMessages());
		//System.debug('\n\n' + twitter.friendsTimeline());
		//System.debug('\n\n' + twitter.getPublicStatuses());
		//System.debug('\n\n' + twitter.tweet('Test using Simons mod\'d client.'));
		//System.debug('\n\n' + twitter.myFollowers());
	}
	
}