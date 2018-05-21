package org.phoebus.applications.alarm;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;

import javax.xml.stream.XMLOutputFactory;
import javax.xml.stream.XMLStreamWriter;

import org.junit.Test;
import org.phoebus.applications.alarm.client.AlarmClientLeaf;
import org.phoebus.applications.alarm.client.AlarmClientNode;
import org.phoebus.applications.alarm.model.AlarmTreeItem;
import org.phoebus.applications.alarm.model.AlarmTreeLeaf;
import org.phoebus.applications.alarm.model.TitleDetail;
import org.phoebus.framework.persistence.IndentingXMLStreamWriter;
import org.phoebus.framework.persistence.XMLUtil;

public class AlarmModelWriterTest
{
	private static XMLStreamWriter writer;

	private static void initWriter (final OutputStream stream) throws Exception
	{
		final XMLStreamWriter base =
	            XMLOutputFactory.newInstance().createXMLStreamWriter(stream, XMLUtil.ENCODING);
	        writer = new IndentingXMLStreamWriter(base);

	        writer.writeStartDocument(XMLUtil.ENCODING, "1.0");
	        // TODO: Does anything else need to be done to initialize the XML writer?

	}

	public static void getModelXML(final AlarmTreeItem<?> item) throws Exception
	{

        getModelXML(item, System.out);
    }

    public static void getModelXML(final AlarmTreeItem<?> item, final OutputStream out) throws Exception
    {
    	initWriter(out);
        getModelXML(item, out, 0);
    }

    private static void getModelXML(final AlarmTreeItem<?> item, final OutputStream out, final int level) throws Exception
    {

    	if (level == 0)
    	{
    		writer.writeStartElement("config");
        	writer.writeAttribute("name", item.getName());

        	getItemXML(item);

        	for (final AlarmTreeItem<?> child : item.getChildren())
                getModelXML(child, out, level+1);

        	writer.writeEndElement();
    	}
    	else if (item instanceof AlarmTreeLeaf)
        {
        	final AlarmTreeLeaf leaf = (AlarmTreeLeaf) item;

        	writer.writeStartElement("pv");
        	writer.writeAttribute("name", item.getName());

        	getLeafXML(leaf);

        	getItemXML(item);

        	writer.writeEndElement();
        }
        else
        {
        	writer.writeStartElement("component");
        	writer.writeAttribute("name", item.getName());

        	getItemXML(item);

        	for (final AlarmTreeItem<?> child : item.getChildren())
                getModelXML(child, out, level+1);

        	writer.writeEndElement();
        }


    }

    private static void getItemXML(final AlarmTreeItem<?> item) throws Exception
    {

    	// Write XML for Guidance
    	final List<TitleDetail> guidance = item.getGuidance();

    	if (!guidance.isEmpty())
    	{
    		getTitleDetailListXML(guidance, "guidance");
    	}

    	// Write XML for Displays
    	final List<TitleDetail> displays = item.getDisplays();

    	if (!displays.isEmpty())
    	{
    		getTitleDetailListXML(displays, "display");
    	}

    	// Write XML for Commands
    	final List<TitleDetail> commands = item.getCommands();

    	if (!commands.isEmpty())
    	{
    		getTitleDetailListXML(commands, "command");
    	}
    	/*
    	 * TODO : Automated actions are not yet implemented.
    	// Write XML for Actions
    	final List<TitleDetail> actions = item.getActions();

    	if (!actions.isEmpty())
    	{
    		getTitleDetailListXML(actions, "automated_action");
    	}
    	*/
    }

    // TODO: This will not work with automated_actions as the XML schema expects a third child "delay" to go along
    // 	     with "title" and "details".
    private static void getTitleDetailListXML(final List<TitleDetail> tdList, final String itemSubType) throws Exception
    {
    	for (final TitleDetail td : tdList)
		{
			// TODO: would a title element ever have empty or null title/detail?
    		writer.writeStartElement(itemSubType);

    		writer.writeStartElement("title");
			writer.writeCharacters(td.title);
			writer.writeEndElement();
			writer.writeStartElement("details");
			writer.writeCharacters(td.detail);
			writer.writeEndElement();

			writer.writeEndElement();
		}
    }

    private static void getLeafXML(final AlarmTreeLeaf leaf) throws Exception
    {
    	final String description = leaf.getDescription();
    	if (description != null && !description.isEmpty())
    	{
    		writer.writeStartElement("description");
    		writer.writeCharacters(description);
    		writer.writeEndElement();
    	}

    	final String enabled = leaf.isEnabled() ? "true" : "false";

		writer.writeStartElement("enabled");
		writer.writeCharacters(enabled);
		writer.writeEndElement();

		final String latching = leaf.isLatching() ? "true" : "false";

		writer.writeStartElement("latching");
		writer.writeCharacters(latching);
		writer.writeEndElement();

		final String annunciating = leaf.isAnnunciating() ? "true" : "false";

		writer.writeStartElement("annunciating");
		writer.writeCharacters(annunciating);
		writer.writeEndElement();

		final int delay = leaf.getDelay();

		// A delay less than zero doesn't make sense but is technically possible.
		if (delay != 0)
		{
			writer.writeStartElement("delay");
			writer.writeCharacters(Integer.toString(delay));
			writer.writeEndElement();
		}

		final int count = leaf.getCount();

		// Count is unsigned so can be assumed greater than 0.
		if (count > 0)
		{
			writer.writeStartElement("count");
			writer.writeCharacters(Integer.toString(count));
			writer.writeEndElement();
		}

		final String filter = leaf.getFilter();
    	if (filter != null && !filter.isEmpty())
    	{
    		writer.writeStartElement("filter");
    		writer.writeCharacters(filter);
    		writer.writeEndElement();
    	}

    }

	public static void close() throws IOException
	{
        try
        {
            // End and close document
            writer.writeEndDocument();
            writer.flush();
            writer.close();
        }
        catch (final Exception ex)
        {
            throw new IOException("Failed to close XML", ex);
        }
    }

	// TODO: Do we need to handle exception better than simply throwing?
	@Test
	public void testAlarmModelWriter() throws Exception
	{
		final AlarmClientNode  root = new AlarmClientNode(null, "Test");

		// Create an area with 2 PV's.
		final AlarmClientNode area1 = new AlarmClientNode(root, "Area1");

		final List<TitleDetail> area1Guidance = new ArrayList<>();

		area1Guidance.add(new TitleDetail("Area1 Guidance Title 1", "Area1 Guidance Detail 1"));
		area1Guidance.add(new TitleDetail("Area1 Guidance Title 2", "Area1 Guidance Detail 2"));

		// Set area1 commands.
		area1.setCommands(area1Guidance);

		final List<TitleDetail> area1Displays = new ArrayList<>();

		area1Displays.add(new TitleDetail("Area1 Display Title 1", "Area1 Display Detail 1"));
		area1Displays.add(new TitleDetail("Area1 Display Title 2", "Area1 Display Detail 2"));

		// Set area1 displays.
		area1.setActions(area1Displays);

		final List<TitleDetail> area1Commands = new ArrayList<>();

		area1Commands.add(new TitleDetail("Area1 Command Title 1", "Area1 Command Detail 1"));
		area1Commands.add(new TitleDetail("Area1 Command Title 2", "Area1 Command Detail 2"));

		// Set area1 commands.
		area1.setCommands(area1Commands);

		final List<TitleDetail> area1Actions = new ArrayList<>();

		area1Actions.add(new TitleDetail("Area1 Action Title 1", "Area1 Action Detail 1"));
		area1Actions.add(new TitleDetail("Area1 Action Title 2", "Area1 Action Detail 2"));

		// Set area1 commands.
		area1.setActions(area1Actions);

		final AlarmClientLeaf a1pv1 = new AlarmClientLeaf(area1, "a1pv1");

		a1pv1.setAnnunciating(true);
		a1pv1.setCount(5);
		a1pv1.setDelay(4);
		a1pv1.setDescription("a1pv1 description");
		a1pv1.setEnabled(true);
		a1pv1.setFilter("a1pv1 filter");
		a1pv1.setLatching(true);

		final AlarmClientLeaf a1pv2 = new AlarmClientLeaf(area1, "a1pv2");
		a1pv2.setDescription("a1pv2 description");

		final AlarmClientNode area2 = new AlarmClientNode(root, "Area2");

		final AlarmClientLeaf a2pv1 = new AlarmClientLeaf(area2, "a2pv1");
		a2pv1.setDescription("a2pv1 description");

		final AlarmClientNode area3 = new AlarmClientNode(area2, "Area3");

		final AlarmClientLeaf a3pv1 = new AlarmClientLeaf(area3, "a3pv1");
		a3pv1.setDescription("a3pv1 description");

		final ByteArrayOutputStream buf = new ByteArrayOutputStream();
        getModelXML(root, buf);
        close();

        final String xml = buf.toString();
        final String[] lines = xml.split("/n");
        for (final String line : lines)
        {
        	System.out.println(line);
        }

        //System.out.println(xml);
	}

}
