import SwiftUI
import ValorantAPI

struct ScoreboardView: View {
	let data: MatchViewData
	@Binding var highlight: PlayerHighlightInfo
	
	@State private var width = 0.0
	@Environment(\.valorantLoad) private var load
	
	var body: some View {
		VStack {
			let sorted = data.details.players.sorted { $0.stats.score > $1.stats.score }
			
			ScrollView(.horizontal, showsIndicators: false) {
				VStack(spacing: ScoreboardRowView.padding) {
					ForEach(sorted) { player in
						ScoreboardRowView(player: player, data: data, highlight: $highlight)
					}
				}
				.padding(.horizontal)
				.frame(minWidth: width)
			}
			.measured { width = $0.width }
			
			AsyncButton("Update Ranks", action: fetchRanks)
				.buttonStyle(.bordered)
		}
	}
	
	private func fetchRanks() async {
		await load {
			for playerID in data.players.keys {
				try await $0.fetchCareerSummary(for: playerID)
			}
		}
	}
}

struct ScoreboardRowView: View {
	static let padding = 6.0
	private static let partyLetters = (UnicodeScalar("A").value...UnicodeScalar("Z").value)
		.map { String(UnicodeScalar($0)!) }
	
	let player: Player
	let data: MatchViewData
	@Binding var highlight: PlayerHighlightInfo
	
	@LocalData private var summary: CareerSummary?
	
	var body: some View {
		let divider = Rectangle()
			.frame(width: 1)
			.blendMode(.destinationOut)
		let relativeColor = data.relativeColor(of: player)
		
		HStack(spacing: Self.padding) {
			AgentImage.icon(player.agentID)
				.aspectRatio(1, contentMode: .fit)
				.dynamicallyStroked(radius: 1, color: .white)
				.background(relativeColor.opacity(0.5))
				.compositingGroup()
				.opacity(highlight.shouldFade(player.id) ? 0.5 : 1)
			
			HStack {
				identitySection
					.foregroundColor(relativeColor)
				
				divider
				
				Text(verbatim: "\(player.stats.score)")
					.frame(width: 60)
				
				divider
				
				KDASummaryView(player: player)
					.frame(width: 120)
				
				if !data.parties.isEmpty {
					divider
					
					partyLabel(for: player.partyID)
						.frame(width: 80)
				}
			}
			.padding(.vertical, Self.padding)
			
			relativeColor
				.frame(width: Self.padding)
		}
		.background(relativeColor.opacity(0.25))
		.frame(height: 44)
		.cornerRadius(Self.padding)
		.compositingGroup() // for the destination-out blending
		.onTapGesture {
			highlight.switchHighlight(to: player)
		}
		.withLocalData($summary, id: player.id)
	}
	
	@ViewBuilder
	var identitySection: some View {
		Text(verbatim: player.gameName)
			.fontWeight(
				highlight.isHighlighting(player.partyID)
					.map { $0 ? .semibold : .regular }
					?? .medium
			)
			.fixedSize()
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.trailing, 4)
		
		Spacer()
		
		if player.id != data.myself?.id {
			NavigationLink(destination: MatchListView(userID: player.id, user: User(player))) {
				Image(systemName: "person.crop.circle.fill")
					.frame(maxHeight: .infinity)
					.padding(.horizontal, 4)
			}
		}
		
		RankInfoView(summary: summary, lineWidth: 2, shouldShowProgress: false, shouldFadeUnranked: true)
			.foregroundColor(nil)
	}
	
	func partyLabel(for party: Party.ID) -> some View {
		Group {
			if let partyIndex = data.parties.firstIndex(of: party) {
				let partyLetter = Self.partyLetters[partyIndex]
				let shouldEmphasize = highlight.isHighlighting(party) == true
				Text("Party \(partyLetter)")
					.fontWeight(shouldEmphasize ? .medium : .regular)
			} else {
				Text("–")
			}
		}
		.opacity(highlight.shouldFade(party) ? 0.5 : 1)
	}
}

#if DEBUG
struct ScoreboardView_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			ScoreboardView(data: PreviewData.singleMatchData, highlight: .constant(.init()))
				.padding(.vertical)
			
			ScoreboardRowView(
				player: PreviewData.singleMatch.players[0],
				data: PreviewData.singleMatchData,
				highlight: .constant(.init())
			)
			.padding()
		}
		.fixedSize(horizontal: true, vertical: true)
		.previewLayout(.sizeThatFits)
	}
}
#endif
