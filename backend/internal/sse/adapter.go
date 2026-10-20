package sse

import "scamshield/internal/moderation"

// NewCommentObserver adapts the hub to moderation's CommentObserver hook.
// Register it (usually inside a moderation.CommentObserverGroup) to stream a
// `comment_created` event for every comment stored by the discussion service.
func NewCommentObserver(hub *Hub) moderation.CommentObserver {
	return &commentObserver{hub: hub}
}

type commentObserver struct {
	hub *Hub
}

// CommentCreated implements moderation.CommentObserver. Publish never blocks.
func (o *commentObserver) CommentCreated(c moderation.Comment) {
	o.hub.Publish(c.ReportID, Event{
		Name: EventCommentCreated,
		Data: moderation.ToCommentDTO(c),
	})
}

// GrokPublisher adapts the hub to the @help bot's event port. The bot defines
// the interface it consumes; this type satisfies it structurally, so neither
// grok nor sse needs to import the other. (The type name is kept for historical
// reasons; the public trigger is @help.)
type GrokPublisher struct {
	hub *Hub
}

// NewGrokPublisher constructs a GrokPublisher.
func NewGrokPublisher(hub *Hub) *GrokPublisher {
	return &GrokPublisher{hub: hub}
}

// GrokThinking emits the immediate "NegevAI is thinking" event. It is called
// inline when the bot accepts a mention, before the job waits for a slot.
func (p *GrokPublisher) GrokThinking(postID, triggerCommentID int64) {
	p.hub.Publish(postID, Event{
		Name: EventGrokThinking,
		Data: grokThinkingPayload{
			PostID:           encodeID(postID),
			TriggerCommentID: encodeID(triggerCommentID),
		},
	})
}

// GrokReplied emits the terminal success event with the full stored reply
// comment. The reply is also announced as a normal `comment_created` event
// (bot replies bypass moderation.CreateComment, so the observer never sees
// them); clients that render both should de-duplicate by comment_id. reply is
// nil only when loading the stored comment failed, in which case the client can
// refetch the thread.
func (p *GrokPublisher) GrokReplied(postID, triggerCommentID, replyCommentID int64, fallback bool, reply *moderation.CommentDTO) {
	if reply != nil {
		p.hub.Publish(postID, Event{Name: EventCommentCreated, Data: *reply})
	}
	p.hub.Publish(postID, Event{
		Name: EventGrokReplied,
		Data: grokRepliedPayload{
			PostID:           encodeID(postID),
			TriggerCommentID: encodeID(triggerCommentID),
			ReplyCommentID:   encodeID(replyCommentID),
			Fallback:         fallback,
			Comment:          reply,
		},
	})
}

// GrokFailed emits the terminal failure event. reason is "skipped" or "error".
func (p *GrokPublisher) GrokFailed(postID, triggerCommentID int64, reason string) {
	p.hub.Publish(postID, Event{
		Name: EventGrokFailed,
		Data: grokFailedPayload{
			PostID:           encodeID(postID),
			TriggerCommentID: encodeID(triggerCommentID),
			Reason:           reason,
		},
	})
}
