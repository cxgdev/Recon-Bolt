import ValorantAPI
import SwiftUI

/// View data for a match, used in many views involved in match details.
struct MatchViewData {
	let details: MatchDetails
	let myself: Player?
	let players: [Player.ID: Player]
	var highlightedPlayer: Player.ID?
	
	init(details: MatchDetails, playerID: Player.ID?) {
		self.details = details
		
		let candidates = details.players.filter { $0.id == playerID }
		assert(candidates.count <= 1)
		self.myself = candidates.first
		
		self.players = .init(values: details.players)
	}
	
	func shouldFade(_ playerID: Player.ID) -> Bool {
		guard let highlightedPlayer = highlightedPlayer else { return false }
		return playerID != highlightedPlayer
	}
	
	mutating func switchHighlight(to playerID: Player.ID) {
		// switch highlight to this player or toggle it off
		highlightedPlayer = highlightedPlayer == playerID ? nil : playerID
	}
	
	func relativeColor(of other: Player) -> Color? {
		let teamColor = relativeColor(of: other.teamID) ?? .valorantBlue
		return other.id == myself?.id ? .valorantSelf : teamColor
	}
	
	func relativeColor(of teamID: Team.ID) -> Color? {
		if let own = myself?.teamID {
			return teamID == own ? .valorantBlue : .valorantRed
		} else {
			return teamID.color
		}
	}
}