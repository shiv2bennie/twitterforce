public virtual class TwitterForce {

	// 
	// Apex Client wrapper for the Twitter API
	//
	// See Twitter REST API documentation
	// http://apiwiki.twitter.com/REST+API+Documentation#update
	//
		
	public String username;
	public String password;
	public TwitterUser user; 


	public virtual class TwitterException extends Exception {}
	
	/** should extend TwitterException, but doesn't seem to want to compile */
	public class AuthenticationException extends TwitterForce.TwitterException {}
		
	public TwitterForce() { }

	/** create a new Twitter client with these twitter credentials
		Calls out to checkCreds to validate credentials.  If successfully validated
		then the User is populated with the returned user object
	 */
	public TwitterForce(String un, String pw) {
		try {
			checkCreds(un, pw);
		} catch (Exception ex) {
			
		}
	}

	protected virtual HttpRequest createRequest(String method, String path, Map<String, String> params) {
		String paramString = '';
		for (String key : params.keySet()) {
			if (params.get(key) != null) {
				paramString += key + '=' + params.get(key) + '&';
			}
		}
		paramString = paramString.substring(0, paramString.length() - 1);
		HttpRequest r = createRequest(method, path);
		if (paramString.length() > 0) {
			r.setBody(paramString);
		}
		return r;
	}
	
	protected virtual HttpRequest createAnonRequest(String method, String path) {
    	HttpRequest req = new HttpRequest();
     	req.setEndpoint(path);
      	req.setMethod(method == null ? 'GET' : method);
      	return req;
	}
	
	protected virtual HttpRequest createRequest(String method, String path) {
    	HttpRequest req = new HttpRequest();
     	req.setEndpoint('http://twitter.com/' + path);
      	req.setMethod(method == null ? 'GET' : method);
      	
      	Blob headerValue = Blob.valueOf(this.username + ':' + this.password);
      	String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
      	req.setHeader('Authorization', authorizationHeader);
      	return req;
    }

    private HttpResponse execute(HttpRequest req) {
      	HttpResponse res = new http().send(req);
      	System.debug(LoggingLevel.FINE, '\n\nReq: \n' + req + '\n\nResp: \n' + res.getBody());
      	if (res.getStatusCode() == 401)
      		throw new AuthenticationException(res.getBody() + '\n\nUsername: ' + this.username + '\nPassword: ' + this.password);
      	else if (res.getStatusCode() != 200)
      		throw new TwitterException(res.getBody());      	
      	return res;
    }
    
	/** post an update, inReplyToStatusId can be null if this is not a reply */
  	public TwitterStatus postUpdate(String msg, String inReplyToStatusId) {
  		return postTweet(new Map<String, String>{ 'status'=>msg, 'in_reply_to_status_id'=>inReplyToStatusId, 'source'=>'twitterforce' });
  	}

	public TwitterUser checkCreds(String un, String pw) {
		this.username = un;
		this.password = pw;

		HttpResponse resp = execute(createRequest('GET', 'account/verify_credentials.xml'));
		if (resp.getStatusCode() == 200) {
			return user = parseUser(getReader(resp.getBody()));
		} else {
			return null;
		}
		return null;
	}
	
	public TwitterForce.RateLimitStatus getRateLimitStatus() {
		HttpResponse resp = execute(createRequest('GET', 'account/rate_limit_status.xml'));
		return parseRateLimitStatus(getReader(resp.getBody()));
	} 
	
	public List<TwitterMessage> getReceivedMessages() {
		HttpResponse resp = execute(createRequest('GET', 'direct_messages.xml'));
		return parseMessages(getReader(resp.getBody()));
	}

	public List<TwitterMessage> getSentMessages() {
		HttpResponse resp = execute(createRequest('GET', 'direct_messages/sent.xml'));
		return parseMessages(getReader(resp.getBody()));
	}

	public TwitterMessage sendMessage(String msg, String recipientId) {
		HttpResponse resp = execute(createRequest('POST', 'direct_messages/new.xml', 
			new Map<String, String>{ 'user'=>recipientId, 'text'=>msg, 'source'=>'twitterforce' }));
		return parseMessage(getReader(resp.getBody()));
	}
	
	public List<TwitterUser> myFollowers() {
		HttpResponse resp = execute(createRequest('GET', 'statuses/followers.xml'));
		return parseUsers(getReader(resp.getBody()));
	}
	
	public List<TwitterStatus> friendsTimeline() {
		HttpResponse resp = execute(createRequest('GET', 'statuses/friends_timeline.xml'));
		return parseStatuses(getReader(resp.getBody()));
	}

	public List<TwitterStatus> getPublicStatuses() {
		HttpResponse resp = execute(createRequest('GET', 'statuses/public_timeline.xml'));
		return parseStatuses(getReader(resp.getBody()));
	}

	public Atom.Feed wordSearch(String word) {
		HttpResponse resp = execute(createAnonRequest('GET', ' http://search.twitter.com/search.atom?q=' + Encodingutil.urlEncode(word, 'UTF-8')));
		Atom a = new Atom();
		return a.parseFeed(getReader(resp.getBody()));
	}
	
	public TwitterStatus tweet(String status) {
		return postTweet(new Map<String, String>{ 'status'=>status, 'source'=>'twitterforce' });
	}
	
	public TwitterStatus tweet(String status, String replyId) {
		System.debug('\n\nTWEET: ' + 'Status is: ' + status);
		return postTweet(new Map<String, String>{ 'status'=>status, 'in_reply_to_status_id'=>replyId, 'source'=>'twitterforce' });
	}

	public TwitterStatus postTweet(Map<String, String> updateParams) {
		HttpResponse resp = execute(createRequest('POST', 'statuses/update.xml', updateParams));
		return parseStatus(getReader(resp.getBody()));
	}
	
    protected virtual XmlStreamReader getReader(String xml) {
    	// TODO
    	/* This is to avoid a bug in XmlStreamReader - 
    	 * it can't handle extended characters
    	*/
    	xml = xml.replaceAll('&#246;', 'o');	
    	xml = xml.replaceAll('&#248;', 'o');
		xml = xml.replaceAll('&#8220;', '"');
		xml = xml.replaceAll('&#8221;', '"');
    	xml = xml.replaceAll('&#[^;]*;', '');
    	
    	XmlStreamReader r = new XmlStreamReader(xml);
		r.setCoalescing(true);
	    r.nextTag(); 
    	return r;
    }

	protected virtual List<TwitterStatus> parseStatuses(XmlStreamReader r) {
		List<TwitterStatus> statuses = new List<TwitterStatus>();
		if (r.getLocalName().equals('statuses')) {
			while (true) {
				r.nextTag();
				if (r.getLocalName().equals('statuses'))
					break;
				statuses.add(parseStatus(r));
			}
		}
		return statuses;
	}	
	
	/** parses a status structure, assumes the reader is on the status element.*/
	private TwitterStatus parseStatus(XmlStreamReader r) {
		TwitterStatus s = null; 
		if (r.getLocalName().equals('status')) {
			s = new TwitterStatus();
			while (true) {
				r.nextTag();
				if (r.getLocalName().equals('user')) {
					s.user = parseUser(r);
					continue;
				} else if (r.getLocalName().equals('status')) {
					break;
				}
				r.next();
				if (!r.hasText()) continue;
				String c = r.getText();
				r.next();
				String n = r.getLocalName();
				if (n.equals('created_at'))
					s.created_at = c;
				else if (n.equals('id'))
					s.id = c;
				else if (n.equals('text'))
					s.text = c;
				else if (n.equals('source'))
					s.source = c;
				else if (n.equals('truncated'))
					s.truncated = c.equalsIgnoreCase('true');
				else if (n.equals('in_reply_to_status_id'))
					s.in_reply_to_status_id = c;
				else if (n.equals('in_reply_to_user_id'))
					s.in_reply_to_user_id = c;
				else if (n.equals('favorited'))
					s.favorited = c.equalsIgnoreCase('true');
			}
		}
		return s;
	}
 
 	protected virtual TwitterForce.RateLimitStatus parseRateLimitStatus(XmlStreamReader r) {
 		TwitterForce.RateLimitStatus s = null;
 		if (r.getLocalName().equals('hash')) {
 			s = new TwitterForce.RateLimitStatus();
 			while (true) {
 				r.nextTag();
 				if (r.getLocalName().equals('hash')) 
 					break;
 				r.next();
 				if (!r.hasText()) continue;
 				String c = r.getText();
 				r.next();
 				String n = r.getLocalName();
 				if (n.equals('remaining-hits')) 
 					s.remaining_hits = Integer.valueOf(c);
 				else if (n.equals('hourly-limit')) 
 					s.hourly_limit = Integer.valueOf(c);
 				else if (n.equals('reset-time')) 
 					s.reset_time = Datetime.valueOf(c.replace('T', ' '));
 				else if (n.equals('reset-time-in-seconds')) 
 					s.reset_time_in_seconds = Integer.valueOf(c);
 			}
 		}
 		return s;
 	} 
 	
 	protected virtual List<TwitterMessage> parseMessages(XmlStreamReader r) {
		List<TwitterMessage> messages = new List<TwitterMessage>();
		if (r.getLocalName().equals('direct-messages')) {
			while (true) {
				r.nextTag();
				if (r.getLocalName().equals('direct-messages'))
					break;
				messages.add(parseMessage(r));
			}
		}
		return messages;
 	} 
 	
 	private List<TwitterUser> parseUsers(XmlStreamReader r) {
		List<TwitterUser> users = new List<TwitterUser>();
		if (r.getLocalName().equals('users')) {
			while (true) {
				r.nextTag();
				if (r.getLocalName().equals('users'))
					break;
				users.add(parseUser(r));
			}
		}
		return users;
 	} 

 	private TwitterMessage parseMessage(XmlStreamReader r) {
 		TwitterMessage m = null;
 		if (r.getLocalName().equals('direct_message')) {
 			m = new TwitterMessage();
 			while (true) {
 				r.nextTag();
 				if (r.getLocalName().equals('direct_message')) {
 					break;
 				} else if (r.getLocalName().equals('sender')) {
 					m.sender = parseUser(r);
 					continue;
 				} else if (r.getLocalName().equals('recipient')) {
 					m.recipient = parseUser(r);
 					continue;
 				}
 				r.next();
				if (!r.hasText()) continue;
				String c = r.getText();
				r.next();
				String n = r.getLocalName();
				if (n.equals('id'))
					m.id = c;
				else if (n.equals('sender_id'))
					m.sender_id = c;
				else if (n.equals('text'))
					m.text = c;
				else if (n.equals('recipient_id'))
					m.recipient_id = c;
				else if (n.equals('created_at'))
					m.created_at = c;
				else if (n.equals('sender_screen_name'))
					m.sender_screen_name = c;
				else if (n.equals('recipient_screen_name'))
					m.recipient_screen_name = c;
 			}
 		}
 		return m;
 	}
 	
	protected virtual TwitterUser parseUser(XmlStreamReader r) {
		TwitterUser u = null;
		if (r.getLocalName().equals('user') || 
				r.getLocalName().equals('sender') || 
				r.getLocalName().equals('recipient')) {
					
			u = new TwitterUser();
			String userName = '';
			while (true) {
			
				r.nextTag();
				
				String pTag = r.getLocalName();
				
				if (r.getLocalName().equals('user')|| 
						r.getLocalName().equals('sender') || 
						r.getLocalName().equals('recipient')) {
					break;
				} else if (r.getLocalName().equals('status')) {
					u.status = parseStatus(r);
					continue;
				} 
				r.next();
				
				if (!r.hasText()) 
					continue;
				String c = r.getText();
				r.next();
				String n = r.getLocalName();
				if (n.equals('id'))
					u.id = c;
				else if (n.equals('name')) {
					userName = c;
					u.name = c; }
				else if (n.equals('screen_name'))
					u.screen_name = c;
				else if (n.equals('location'))
					u.location = c;
				else if (n.equals('description'))
					u.description = c;
				else if (n.equals('profile_image_url'))
					u.profile_image_url = c;
				else if (n.equals('url'))
					u.url = c;
				else if (n.equals('protected')) 
					u.is_protected = c.equalsIgnoreCase('true');
				else if (n.equals('followers_count'))
					u.followers_count = Integer.valueOf(c);
				else if (n.equals('profile_background_color'))
					u.profile_background_color = c;
				else if (n.equals('profile_text_color'))
					u.profile_text_color = c;
				else if (n.equals('profile_link_color'))
					u.profile_link_color = c;
				else if (n.equals('profile_sidebar_fill_color'))
					u.profile_sidebar_fill_color = c;
				else if (n.equals('profile_sidebar_border_color'))
					u.profile_sidebar_border_color = c;
				else if (n.equals('friends_count'))
					u.friends_count = Integer.valueOf(c);
				else if (n.equals('created_at'))
					u.created_at = c;
				else if (n.equals('favourites_count'))
					u.favourites_count = Integer.valueOf(c);
				else if (n.equals('utc_offset'))
					u.utc_offset = Integer.valueOf(c);
				else if (n.equals('time_zone'))
					u.time_zone = c;
				else if (n.equals('profile_background_image_url'))
					u.profile_background_image_url = c;
				else if (n.equals('profile_background_tile'))
					u.profile_background_tile = c.equalsIgnoreCase('true');
				else if (n.equals('following'))
					u.following = c.equalsIgnoreCase('true');
				else if (n.equals('notifications'))
					u.notifications = c.equalsIgnoreCase('true');
				else if (n.equals('statuses_count'))
					u.statuses_count = Integer.valueOf(c);
			}
		}
		return u;
	}

	public class RateLimitStatus {
		public Integer remaining_hits { get; set; }
		public Integer hourly_limit { get; set; }
		public DateTime reset_time { get; set ;}
		public Integer reset_time_in_seconds { get; set; }
	}
	
	/*public class User {
	
		public String Id { get; set; }
		public String name { get; set; }
		public String screen_name { get; set; }
		public String description { get; set; }
		public String location { get; set; }
		public String profile_image_url { get; set; }
		public String url { get; set; }
		public Boolean is_protected { get; set; }
		public Integer followers_count { get; set; }
		public String profile_background_color { get; set; }
		public String profile_text_color { get; set; }
	  	public String profile_link_color { get; set; }
	  	public String profile_sidebar_fill_color { get; set; }
	  	public String profile_sidebar_border_color { get; set; } 
	  	public Integer friends_count { get; set; }
	  	public String created_at { get; set; }
	  	public Integer favourites_count { get; set; }
	  	public Integer utc_offset { get; set; }
	  	public String time_zone { get; set; }
	  	public String profile_background_image_url { get; set; }
	  	public Boolean profile_background_tile { get; set; }
	  	public Boolean following { get; set; }
	  	public Boolean notifications { get; set; }
	  	public Integer statuses_count { get; set; }
	  	public TwitterStatus status { get; set; }
	  	
	}	*/

	/*public class Status {
	
		public String created_at {get; set;}
		public String Id { get; set; } 
		public String text { get; set; }
		public String source { get; set; }
		public Boolean truncated { get; set; }
		public String in_reply_to_status_id { get; set; }
		public String in_reply_to_user_id { get; set; }
		public Boolean favorited { get; set; }
		public TwitterForce.User user { get; set; }
		
	}*/

	/*public class Message {
		public String id { get; set; }
		public String sender_id { get; set; }
		public String text { get; set; }
		public String recipient_id { get; set; }
		public String created_at { get; set; }
		public String sender_screen_name { get; set; }
		public String recipient_screen_name { get; set; }
		public TwitterUser sender { get; set; }
		public TwitterUser recipient { get; set; }
		
		public Message() {}
		 
		public Message(String text, String recipient) {
			this.text = text;
		}
	}*/
}