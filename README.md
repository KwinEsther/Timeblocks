# TimeBlocks v2

A decentralized Pomodoro timer built on the Stacks blockchain using Clarity. TimeBlocks helps users boost productivity by tracking focus sessions, rewarding them with tokens, and providing an immutable record of their progress.

## Features

- **Blockchain-based Tracking:** Immutable logs of completed Pomodoro sessions stored on the blockchain.
- **Dynamic Token Rewards:** Users earn tokens for completing focus sessions, with bonus rewards for maintaining streaks.
- **Customizable Session Lengths:** Users can set their preferred Pomodoro session duration.
- **Streak Tracking:** The contract tracks and rewards consistent daily usage.
- **Immutable Productivity Records:** Transparent, tamper-proof logs for productivity tracking.
- **Accountability and Motivation:** Incentives for maintaining consistent productivity.

## How It Works

1. **Start a Session:**
   Users initiate a Pomodoro timer with their chosen duration.

2. **Complete the Session:**
   Upon successful completion, the session is recorded on the blockchain, and users are rewarded with tokens.

3. **Maintain Streaks:**
   Consistent daily usage increases the user's streak, leading to higher rewards.

4. **Track Progress:**
   Users can view their focus streaks and overall productivity records using read-only functions.

5. **Claim Rewards:**
   Accumulated tokens can be claimed by users, encouraging continued engagement.

## Smart Contract Functions

- `start-session`: Begins a new Pomodoro session with a specified duration.
- `complete-session`: Ends the current session, calculates rewards, and updates streaks.
- `claim-rewards`: Allows users to claim their accumulated reward tokens.
- `get-session-count`: Retrieves the total number of completed sessions for a user.
- `get-reward-balance`: Checks the current reward token balance for a user.
- `get-user-streak`: Returns the current streak count for a user.
- `get-global-stats`: Provides overall statistics on total sessions and minted tokens.

## Future Improvements

- Integration with front-end applications for a seamless user experience.
- Implementation of social features for community engagement and competitions.
- Expansion of reward mechanisms, potentially including NFTs for significant achievements.