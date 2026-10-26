import { EC2Client, DescribeInstancesCommand } from "@aws-sdk/client-ec2";

export const handler = async (event) => {
    const query = event?.queryStringParameters || {};
    const tagName = query.tagName || process.env.DEFAULT_TAG_NAME || "cluster";
    const tagValue = query.tagValue || process.env.DEFAULT_TAG_VALUE || "cassandra-cluster";

    const region = process.env.AWS_REGION;
    const client = new EC2Client({ region });

    const command = new DescribeInstancesCommand({
        Filters: [
            { Name: `tag:${tagName}`, Values: [tagValue] },
            { Name: "instance-state-code", Values: ["16"] }
        ]
    });

    try {
        const response = await client.send(command);
        let parsedInstances = [];

        response.Reservations.forEach(val => {
            parsedInstances = [...parsedInstances, ...val.Instances];
        });

        parsedInstances = parsedInstances.sort((a, b) => (a.LaunchTime - b.LaunchTime));

        const seedIps = parsedInstances.slice(0, 5).map(instance => {
            if (instance.NetworkInterfaces.length >= 2) {
                const sortedEnis = instance.NetworkInterfaces.sort((a, b) =>
                    (b.Attachment.AttachTime - a.Attachment.AttachTime)
                );
                return sortedEnis[0].PrivateIpAddress;
            }
            return instance.PrivateIpAddress;
        });

        return {
            statusCode: 200,
            headers: {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            body: seedIps.join(",")
        };
    } catch (error) {
        console.error("Error describing instances:", error);
        return {
            statusCode: 500,
            headers: {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            body: JSON.stringify({ error: "Failed to discover seed nodes" })
        };
    }
};
