
// pragma solidity ^0.8.9;

// contract CrowdFunding {
//     struct Campaign {
//         address owner;
//         string title;
//         string description;
//         uint256 target;
//         uint256 deadline;
//         uint256 amountCollected;
//         string image;
//         address[] donators;
//         uint256[] donations;
//     }

//     mapping(uint256 => Campaign) public campaigns;

//     uint256 public numberOfCampaigns = 0;

//     function createCampaign(address _owner, string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
//         Campaign storage campaign = campaigns[numberOfCampaigns];

//         require(campaign.deadline < block.timestamp, "The deadline should be a date in the future.");

//         campaign.owner = _owner;
//         campaign.title = _title;
//         campaign.description = _description;
//         campaign.target = _target;
//         campaign.deadline = _deadline;
//         campaign.amountCollected = 0;
//         campaign.image = _image;

//         numberOfCampaigns++;

//         return numberOfCampaigns - 1;
//     }

//     function donateToCampaign(uint256 _id) public payable {
//         uint256 amount = msg.value;

//         Campaign storage campaign = campaigns[_id];

//         campaign.donators.push(msg.sender);
//         campaign.donations.push(amount);

//         (bool sent,) = payable(campaign.owner).call{value: amount}("");

//         if(sent) {
//             campaign.amountCollected = campaign.amountCollected + amount;
//         }
//     }

//     function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
//         return (campaigns[_id].donators, campaigns[_id].donations);
//     }

//     function getCampaigns() public view returns (Campaign[] memory) {
//         Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

//         for(uint i = 0; i < numberOfCampaigns; i++) {
//             Campaign storage item = campaigns[i];

//             allCampaigns[i] = item;
//         }

//         return allCampaigns;
//     }
// }

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        bool withdrawn;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    function createCampaign(address _owner,string memory _title, string memory _description, uint256 _target, uint256 _deadline, string memory _image) public returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];                        

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;
        campaign.withdrawn = false;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable{
        require(_id < numberOfCampaigns, "campaign does not exist");

        Campaign storage campaign = campaigns[_id];

        require(block.timestamp <= campaign.deadline, "campaign deadline has passed");
        require(!campaign.withdrawn, "Funds have already been withdrawn");

        campaign.donators.push(msg.sender);
        campaign.donations.push(msg.value);

        campaign.amountCollected = campaign.amountCollected + msg.value;

    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function withdraw(uint256 _id) public payable{
        require(_id < numberOfCampaigns, "campaign does not exist");

        Campaign storage campaign = campaigns[_id];

        require(msg.sender == campaign.owner, "Only the campaign owner can withdraw funds");
        require(campaign.target < campaign.amountCollected, "campaign goal has not been reached");
        require(!campaign.withdrawn, "Funds have already been withdrawn");

        campaign.withdrawn = true;

        payable(msg.sender).transfer(campaign.amountCollected);
    }    

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }

    function returnFunds(uint256 _id) public payable returns (uint) {
        require(_id < numberOfCampaigns, "campaign does not exist");

        Campaign storage campaign = campaigns[_id];

        require(campaign.amountCollected < campaign.target , "campaign goal has been reached");
        require(!campaign.withdrawn, "Funds have already been withdrawn");
        require(campaign.deadline <= block.timestamp, "campaign deadline has not passed");
        require(campaign.amountCollected > 0, "There are no Donation to refund");

        campaign.amountCollected = 0;

        for (uint256 i = 0; i < campaigns[_id].donators.length; i++) {
            address contributor = campaigns[_id].donators[i]; // Cast uint256 to address
            uint256 amount = campaigns[_id].donations[i];
            campaigns[_id].donations[i] = 0;
            if (amount > 0) {
                payable(contributor).transfer(amount);
            }
        }
        return campaigns[_id].donators.length;
    }

}