/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TwiiterForceTest {

	private class TwitterForceTester extends TwitterForce {
		TwitterForceTester(String u, String p) {
			super(u,p);
		}
		
		public override List<Status> parseStatuses(String x) {
			return super.parseStatuses(x);
		}
		
		public override HttpRequest createRequest(String m, String p) {
			return super.createRequest(m,p);
		}
	}
	
    static testMethod void testAuthHeader() {
    	TwitterForceTester tf = new TwitterForceTester('foo','bar');
    	HttpRequest r = tf.createRequest('GET', 'foo');
    	System.assertEquals('Basic Zm9vOmJhcg==', r.getHeader('Authorization'));
    	System.assertEquals('GET', r.getMethod());
    	System.assertEquals('http://twitter.com/foo', r.getEndpoint());    	
    }
    
    static testMethod void testStatusesParser() {
    	TwitterForceTester t = new TwitterForceTester('foo','bar');
    	List<TwitterForce.Status> statuses = t.parseStatuses(getStatuses());
    	System.assertEquals(2, statuses.size());
    	TwitterForce.Status s = statuses[0];
    	System.assertEquals('Sun Nov 02 03:20:06 +0000 2008', s.createdAt);
    	System.assertEquals('985929063', s.id);
    	System.assertEquals('@superfell not using twitter api yet from apex. show us what it can do!', s.text);
    	System.assertEquals('<a href="http://github.com/dustin/twitterspy">TwitterSpy</a>', s.source);
    	System.assertEquals(false, s.truncated);
    	System.assertEquals('985892918', s.inReplyToStatusId);
    	System.assertEquals('17104583', s.inReplyToUserId);
    	System.assertEquals(false, s.favorited);
    	System.assertEquals('8420652', s.user.id);
    	System.assertEquals('Scott Hemmeter', s.user.name);
    	System.assertEquals('arrowpointe', s.user.screenName);
    	System.assertEquals('Southern Cal, USA', s.user.location);
    	System.assertEquals('Services & Applications on the Salesforce.com platform', s.user.description);
    	System.assertEquals('http://s3.amazonaws.com/twitter_production/profile_images/21840362/twitter_normal.jpg', s.user.profileImageUrl);
    	System.assertEquals('http://sfdc.arrowpointe.com', s.user.url);
    	System.assertEquals(false, s.user.isProtected);
    	System.assertEquals(91, s.user.followersCount);
    }
    
    static String getStatuses() {
    	return '<?xml version="1.0" encoding="UTF-8"?>\n' +
				'<statuses type="array">\n' +
				'<status>\n' +
  				'<created_at>Sun Nov 02 03:20:06 +0000 2008</created_at>\n' +
  				'<id>985929063</id>\n' +
  				'<text>@superfell not using twitter api yet from apex. show us what it can do!</text>\n' +
  				'<source>&lt;a href=&quot;http://github.com/dustin/twitterspy&quot;&gt;TwitterSpy&lt;/a&gt;</source>\n' +
  				'<truncated>false</truncated>\n' +
  				'<in_reply_to_status_id>985892918</in_reply_to_status_id>\n' +
  				'<in_reply_to_user_id>17104583</in_reply_to_user_id>\n' +
  				'<favorited>false</favorited>\n' +
  				'<user>\n' +
    				'<id>8420652</id>\n' +
    				'<name>Scott Hemmeter</name>\n' +
    				'<screen_name>arrowpointe</screen_name>\n' +
    				'<location>Southern Cal, USA</location>\n' +
    				'<description>Services &amp; Applications on the Salesforce.com platform</description>\n' +
    				'<profile_image_url>http://s3.amazonaws.com/twitter_production/profile_images/21840362/twitter_normal.jpg</profile_image_url>\n' +
    				'<url>http://sfdc.arrowpointe.com</url>\n' +
    				'<protected>false</protected>\n' +
    				'<followers_count>91</followers_count>\n' +
  				'</user>\n' +
				'</status>\n' +
				'<status>\n' +
  				'<created_at>Sun Nov 02 03:09:51 +0000 2008</created_at>\n' +
  				'<id>985920139</id>\n' +
  				'<text>This Edge shave gel commercial is just over the top... stupid.. but funny in a way. http://tinyurl.com/4z8wu9</text>\n' +
  				'<source>&lt;a href=&quot;http://www.tweetdeck.com/&quot;&gt;TweetDeck&lt;/a&gt;</source>\n' +
				'<truncated>false</truncated>\n' +
 				'<in_reply_to_status_id></in_reply_to_status_id>\n' +
  				'<in_reply_to_user_id></in_reply_to_user_id>\n' +
  				'<favorited>false</favorited>\n' +
  				'<user>\n' +
    				'<id>705673</id>\n' +
    				'<name>Michael Wilde</name>\n' +
    				'<screen_name>michaelwilde</screen_name>\n' +
    				'<location>Victorian Oaks Ln &amp; Hidden</location>\n' +
    				'<description>Pre-Sales talent, bleeding edge marketing specialist</description>\n' +
    				'<profile_image_url>http://s3.amazonaws.com/twitter_production/profile_images/61348859/image_normal.png</profile_image_url>\n' +
    				'<url></url>\n' +
    				'<protected>false</protected>\n' +
    				'<followers_count>250</followers_count>\n' +
  				'</user>\n' +
				'</status>\n' +
				'</statuses>';
    }
}