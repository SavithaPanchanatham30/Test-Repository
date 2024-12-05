trigger ExplanationNoteTrigger on ExplanationNoteCreatedEvent__e(after insert) {
  new ExplanationNoteTriggerHandler().run();
}