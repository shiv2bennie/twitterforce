public class TweetTest {

	private static TwitterForce twitter;
	 
	public static void main() {
		twitter = new TwitterForce();
		TwitterUser u = twitter.checkCreds('<username>', '<password>');
		System.debug(twitter.wordSearch('"AT&T earnings"'));
		//System.debug('\n\n' + twitter.getRateLimitStatus());
		//System.debug('\n\n' + twitter.getReceivedMessages());
		//System.debug('\n\n' + twitter.friendsTimeline()); 
		//System.debug('\n\n' + twitter.getPublicStatuses());
		//System.debug('\n\n' + twitter.tweet('Test using Simons mod\'d client.'));
		//System.debug('\n\n' + twitter.myFollowers());
	}
	
}